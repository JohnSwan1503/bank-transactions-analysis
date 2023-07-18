CREATE OR REPLACE FUNCTION upsert_rules(
        rule_year INTEGER,
        overdraft_fee MONEY,
        minimum_transactions INTEGER,
        minimum_transactions_fee MONEY,
        maximum_transactions INTEGER,
        maximum_transactions_fee MONEY
    ) RETURNS VOID AS $$ BEGIN
INSERT INTO rules (
        rule_year,
        overdraft_fee,
        minimum_transactions,
        minimum_transactions_fee,
        maximum_transactions,
        maximum_transactions_fee
    )
VALUES (
        rule_year,
        overdraft_fee,
        minimum_transactions,
        minimum_transactions_fee,
        maximum_transactions,
        maximum_transactions_fee
    ) ON CONFLICT (rule_year) DO
UPDATE
SET overdraft_fee = excluded.overdraft_fee,
    minimum_transactions = excluded.minimum_transactions,
    minimum_transactions_fee = excluded.minimum_transactions_fee,
    maximum_transactions = excluded.maximum_transactions,
    maximum_transactions_fee = excluded.maximum_transactions_fee;
END;
$$ LANGUAGE plpgsql;