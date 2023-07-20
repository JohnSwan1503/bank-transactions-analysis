-- Populate the `rules` table with some default values
SELECT
    upsert_rules(2023, money '35.00', 10, money '10.00', 100, money '50.00');

-- Populate the `accounts` table with some data for all 4 accounts for the start of 2023
INSERT INTO accounts (account_type, created_date)
SELECT * FROM generate_accounts(100, ARRAY[10, 4, 1]);
SELECT * FROM accounts;

-- Populate the `transactions` table with some data for all 4 accounts for the start of 2023
INSERT INTO transactions(account_id, transaction_amount, transaction_date)
SELECT
    account_id,
    transaction_amount,
    transaction_date
FROM
    generate_transactions(50000, 2020)
ORDER BY
    transaction_date ASC,
    account_id ASC;


