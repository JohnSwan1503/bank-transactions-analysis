CREATE TABLE accounts (
    account_id          serial      NOT NULL,
    account_type        accounttype NOT NULL,
    created_date        date        NOT NULL,
                        CONSTRAINT  account_id_pk           PRIMARY KEY (account_id),
                        CONSTRAINT  created_date_check      CHECK       (created_date BETWEEN '2019-01-01'::date AND '2030-12-31'::date)
);

ALTER TABLE accounts ADD COLUMN 
    starting_balance    money       NOT NULL    GENERATED   ALWAYS AS (generate_starting_balance(account_type)) STORED;

CREATE TABLE transactions (
    transaction_id      serial          NOT NULL,
    account_id          integer         NOT NULL,
    transaction_date    date            NOT NULL,
    transaction_amount  money           NOT NULL,
                        CONSTRAINT      transaction_id_pk       PRIMARY KEY (transaction_id),
                        CONSTRAINT      transaction_date_check  CHECK       (transaction_date BETWEEN '2020-01-01'::date AND '2030-12-31'::date)
);

ALTER TABLE transactions ADD COLUMN 
    transaction_type    transactiontype NOT NULL    GENERATED   ALWAYS AS (generate_transaction_type(transaction_amount)) STORED;

CREATE TABLE rules (
    rule_year       integer     NOT NULL,
    account_type    accounttype NOT NULL,
    rule_type       ruletype    NOT NULL,
    fee             feetype     NOT NULL,
                    CONSTRAINT  rules_pk            PRIMARY KEY (rule_year, account_type, rule_type),
                    CONSTRAINT  rule_year_check     CHECK       (rule_year BETWEEN 2020 AND 2030)
)

