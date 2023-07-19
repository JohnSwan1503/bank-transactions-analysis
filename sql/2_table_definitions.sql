CREATE TABLE IF NOT EXISTS accounts(
    account_id integer NOT NULL PRIMARY KEY,
    account_type accountType NOT NULL DEFAULT 'personal' ::accountType,
    created_on date NOT NULL CHECK (created_on >= '01-01-2020'::date),
    starting_balance GENERATED ALWAYS AS ( CASE WHEN account_type = 'personal'::accountType THEN money '1000.00'
    WHEN account_type = 'business'::accountType THEN money '10000.00'
    WHEN account_type = 'executiveSelect'::accountType THEN money '10000.00'
    END) STORED
);

CREATE TABLE IF NOT EXISTS transactions(
    transaction_id serial NOT NULL PRIMARY KEY,
    account_id integer NOT NULL FOREIGN KEY REFERENCES accounts(account_id),
    transaction_date date NOT NULL CHECK (transaction_date >= '01-01-2020'::date),
    transaction_amount money NOT NULL,
    transaction_type transactionType GENERATED ALWAYS AS ( CASE WHEN transaction_amount < money '0.00' THEN
        'debit'::transactionType
    ELSE
        'credit'::transactionType
    END) STORED
);

CREATE TABLE IF NOT EXISTS rules(
    rule_year integer NOT NULL CHECK (rule_year >= 2020),
    account_type accountType NOT NULL,
    rule_type ruleType NOT NULL,
    fee feeType NOT NULL PRIMARY KEY (rule_year, account_type, rule_type)
);

