CREATE DATABASE loja_tech
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE loja_tech;

CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    estoque INT NOT NULL DEFAULT 0,
    estoque_minimo INT NOT NULL DEFAULT 5,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    data_nascimento DATE,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pendente','processando','enviado','entregue','cancelado') DEFAULT 'pendente',
    valor_total DECIMAL(10,2) DEFAULT 0.00,
    observacao TEXT,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE itens_pedido (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantidade * preco_unitario) STORED,
    CONSTRAINT fk_item_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    CONSTRAINT fk_item_produto FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

CREATE TABLE log_operacoes (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    tabela_afetada VARCHAR(100),
    operacao VARCHAR(50),
    descricao TEXT,
    usuario VARCHAR(100) DEFAULT (CURRENT_USER()),
    data_operacao DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- valores

INSERT INTO categorias (nome, descricao) VALUES
('Notebooks', 'Notebooks e laptops'),
('Smartphones', 'Celulares e smartphones'),
('Periféricos', 'Teclados, mouses, headsets'),
('Monitores', 'Monitores e telas'),
('Armazenamento', 'HDs, SSDs e pen drives');

INSERT INTO produtos (id_categoria, nome, preco, estoque, estoque_minimo) VALUES
(1, 'Notebook Dell Inspiron 15', 3499.90, 25, 5),
(1, 'Notebook Lenovo IdeaPad 3', 2899.00, 18, 5),
(2, 'Samsung Galaxy S24', 4299.00, 40, 10),
(2, 'iPhone 15', 6499.00, 15, 5),
(3, 'Teclado Mecânico Redragon', 249.90, 60, 10),
(3, 'Mouse Logitech G502', 349.90, 45, 10),
(3, 'Headset HyperX Cloud II', 499.90, 30, 8),
(4, 'Monitor LG UltraWide 29"', 1599.00, 12, 3),
(4, 'Monitor Samsung Curvo 27"', 1899.00, 10, 3),
(5, 'SSD Kingston 480GB', 219.90, 80, 15),
(5, 'HD Externo Seagate 1TB', 329.90, 35, 8);

INSERT INTO clientes (nome, email, cpf, telefone, data_nascimento) VALUES
('Ana Silva', 'ana.silva@email.com', '12345678901', '11987654321', '1995-03-15'),
('Bruno Oliveira', 'bruno.oliveira@email.com', '23456789012', '11976543210', '1990-07-22'),
('Carla Santos', 'carla.santos@email.com', '34567890123', '21965432109', '1988-11-08'),
('Daniel Costa', 'daniel.costa@email.com', '45678901234', '31954321098', '2000-01-30'),
('Elena Ferreira', 'elena.ferreira@email.com', '56789012345', '41943210987', '1998-06-12');

INSERT INTO pedidos (id_cliente, status, valor_total) VALUES
(1, 'entregue', 3749.80),
(2, 'enviado', 4299.00),
(3, 'pendente', 1099.70),
(1, 'processando', 6499.00),
(4, 'cancelado', 249.90);

INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario) VALUES
(1, 1, 1, 3499.90),
(1, 5, 1, 249.90),
(2, 3, 1, 4299.00),
(3, 6, 1, 349.90),
(3, 5, 3, 249.90),
(4, 4, 1, 6499.00),
(5, 5, 1, 249.90);


-- atualizar_preco_categoria
DROP PROCEDURE IF EXISTS atualizar_preco_categoria;

DELIMITER //

CREATE PROCEDURE atualizar_preco_categoria(
    IN p_id_categoria INT,
    IN p_percentual DECIMAL(5,2),
    OUT p_qtd_alterados INT,
    OUT p_mensagem VARCHAR(255)
)
BEGIN
    DECLARE v_categoria_existe INT DEFAULT 0;
    DECLARE v_nome_categoria VARCHAR(100);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_qtd_alterados = 0;
        SET p_mensagem = 'ERRO: Falha ao atualizar os preços da categoria.';
    END;

    IF p_percentual IS NULL OR p_percentual = 0 THEN
        SET p_qtd_alterados = 0;
        SET p_mensagem = 'AVISO: O percentual de ajuste não pode ser zero.';

    ELSEIF p_percentual < -50.00 OR p_percentual > 100.00 THEN
        SET p_qtd_alterados = 0;
        SET p_mensagem = 'ERRO: Percentual inválido. O ajuste deve estar entre -50% e +100%.';

    ELSE
        SELECT COUNT(*), MAX(nome)
        INTO v_categoria_existe, v_nome_categoria
        FROM categorias
        WHERE id_categoria = p_id_categoria AND ativo = TRUE;

        IF v_categoria_existe = 0 THEN
            SET p_qtd_alterados = 0;
            SET p_mensagem = 'ERRO: Categoria não encontrada ou inativa.';
        ELSE
            START TRANSACTION;

            UPDATE produtos
            SET preco = ROUND(preco * (1 + (p_percentual / 100)), 2)
            WHERE id_categoria = p_id_categoria
              AND ativo = TRUE;

            SET p_qtd_alterados = ROW_COUNT();

            INSERT INTO log_operacoes (tabela_afetada, operacao, descricao)
            VALUES (
                'produtos',
                'UPDATE',
                CONCAT('Reajuste de ', p_percentual, '% na categoria "', v_nome_categoria, '" (ID ', p_id_categoria, '). Produtos alterados: ', p_qtd_alterados)
            );

            COMMIT;

            SET p_mensagem = CONCAT('Sucesso! ', p_qtd_alterados, ' produto(s) atualizado(s) na categoria ', v_nome_categoria, '.');
        END IF;
    END IF;
END //

DELIMITER ;

-- consultar_extrato_cliente
DROP PROCEDURE IF EXISTS consultar_extrato_cliente;

DELIMITER //

CREATE PROCEDURE consultar_extrato_cliente(
    IN p_id_cliente INT
)
BEGIN
    DECLARE v_cliente_existe INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_cliente_existe
    FROM clientes
    WHERE id_cliente = p_id_cliente;

    IF v_cliente_existe = 0 THEN
        SELECT CONCAT('ERRO: Cliente com ID ', IFNULL(p_id_cliente, 'NULO'), ' não encontrado.') AS mensagem;
    ELSE
        -- Dados do cliente
        SELECT 
            nome,
            email,
            telefone,
            criado_em AS data_cadastro
        FROM clientes
        WHERE id_cliente = p_id_cliente;

        -- Todos os pedidos do cliente
        SELECT 
            id_pedido AS numero,
            data_pedido AS data,
            status,
            valor_total
        FROM pedidos
        WHERE id_cliente = p_id_cliente
        ORDER BY data_pedido DESC;

        -- Resumo financeiro do cliente
        SELECT 
            COUNT(id_pedido) AS total_pedidos,
            IFNULL(SUM(valor_total), 0.00) AS valor_total_gasto,
            IFNULL(ROUND(AVG(valor_total), 2), 0.00) AS ticket_medio,
            MAX(data_pedido) AS ultimo_pedido
        FROM pedidos
        WHERE id_cliente = p_id_cliente
          AND status <> 'cancelado';
    END IF;
END //

DELIMITER ;


-- Testes de execução

CALL atualizar_preco_categoria(1, 10.00, @qtd, @msg);
SELECT @qtd AS qtd_alterados, @msg AS mensagem;

CALL atualizar_preco_categoria(1, -60.00, @qtd, @msg);
SELECT @qtd AS qtd_alterados, @msg AS mensagem;

CALL atualizar_preco_categoria(1, 0, @qtd, @msg);
SELECT @qtd AS qtd_alterados, @msg AS mensagem;

SELECT * FROM log_operacoes;

CALL consultar_extrato_cliente(1);
CALL consultar_extrato_cliente(999);