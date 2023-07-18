CREATE TABLE IF NOT EXISTS accounts (
    account_id INTEGER NOT NULL PRIMARY KEY,
    account_type accountType NOT NULL DEFAULT 'personal',
    created_on DATE NOT NULL DEFAULT "12-31-2022"::DATE,
);
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL NOT NULL PRIMARY KEY,
    account_id INTEGER NOT NULL FOREIGN KEY REFERENCES accounts (account_id),
    transaction_date DATE NOT NULL,
    transaction_amount MONEY NOT NULL,
    transaction_type transactionType GENERATED ALWAYS AS (
        CASE
            WHEN transaction_amount < MONEY '0.00' THEN 'debit'::transactionType
            ELSE 'credit'::transactionType
        END
    ) STORED
);
CREATE TABLE IF NOT EXISTS rules (
    rule_year INTEGER NOT NULL DEFAULT 2023,
    overdraft_fee MONEY NOT NULL,
    minimum_transactions INTEGER NOT NULL,
    minimum_transactions_fee MONEY NOT NULL,
    maximum_transactions INTEGER NOT NULL,
    maximum_transactions_fee MONEY NOT NULL,
    PRIMARY KEY (rule_year)
);