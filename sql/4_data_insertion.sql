-- Populate the `rules` table with some default values
SELECT upsert_rules(
        2023,
        money '35.00',
        10,
        money '10.00',
        100,
        money '50.00'
    );
--
-- Populate the `accounts` table with some data for all 4 accounts for the start of 2023
INSERT INTO accounts (
        account_id,
        account_balance_jan1,
        account_balance_year
    )
VALUES (1, 1000.00, 2023),
    (2, 1000.00, 2023),
    (3, 1000.00, 2023),
    (4, 1000.00, 2023);
--
-- Populate the `transactions` table with some data for all 4 accounts for the start of 2023
INSERT INTO transactions (
        account_id,
        transaction_amount,
        transaction_date
    )
SELECT account_id,
    transaction_amount,
    transaction_date
FROM generate_transactions(2023)
ORDER BY transaction_date ASC,
    account_id ASC;
-- DELETE ALL TRANSACTIONS FROM THE `transactions` TABLE