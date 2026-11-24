# Stored Procedures no MySQL — TechStore (`loja_tech`)

Atividade prática de Banco de Dados focada na criação de **Stored Procedures** no MySQL para automatizar regras de negócio, validações e consultas gerenciais do e-commerce fictício **TechStore**.

---

## O que este projeto faz?

O script SQL deste repositório cria toda a estrutura do banco de dados `loja_tech` (tabelas de categorias, produtos, clientes, pedidos, itens e auditoria), insere os dados iniciais de teste e implementa duas Stored Procedures principais:

### 1. `atualizar_preco_categoria`
Aplica um reajuste percentual (aumento ou desconto) em todos os produtos ativos de uma categoria específica de uma só vez.

- **Parâmetros de entrada (`IN`):** `p_id_categoria` (ID da categoria) e `p_percentual` (porcentagem de ajuste).
- **Parâmetros de saída (`OUT`):** `p_qtd_alterados` (quantidade de produtos atualizados) e `p_mensagem` (status da operação).
- **Regras de negócio e segurança:**
  - Bloqueia percentuais iguais a `0` ou nulos.
  - Limita o desconto máximo a **50%** (`-50.00`) e o aumento máximo a **100%** (`+100.00`).
  - Verifica se a categoria existe e está ativa antes de alterar qualquer dado.
  - Executa a atualização dentro de uma transação (`START TRANSACTION` / `COMMIT` / `ROLLBACK`) e grava o histórico na tabela `log_operacoes`.

### 2. `consultar_extrato_cliente`
Gera um relatório completo do histórico de um cliente a partir do seu ID.

- **Parâmetro de entrada (`IN`):** `p_id_cliente` (ID do cliente).
- **Retorno:**
  - Caso o cliente não exista, exibe uma mensagem de erro amigável via `SELECT`.
  - Caso exista, retorna **3 conjuntos de resultados (Result Sets)**:
    1. **Dados cadastrais:** nome, e-mail, telefone e data de cadastro.
    2. **Histórico de pedidos:** número, data, status e valor total de cada pedido.
    3. **Resumo financeiro:** total de pedidos válidos, valor total gasto, ticket médio e data da última compra.

---

