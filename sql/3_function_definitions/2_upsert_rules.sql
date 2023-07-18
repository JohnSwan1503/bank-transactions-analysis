CREATE OR REPLACE FUNCTION upsert_rules(
        _rule_year INTEGER,
        _overdraft_fee MONEY,
        _minimum_transactions INTEGER,
        _minimum_transactions_fee MONEY,
        _maximum_transactions INTEGER,
        _maximum_transactions_fee MONEY
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
        _rule_year,
        _overdraft_fee,
        _minimum_transactions,
        _minimum_transactions_fee,
        _maximum_transactions,
        _maximum_transactions_fee
    ) ON CONFLICT (rule_year) DO
UPDATE
SET overdraft_fee = excluded.overdraft_fee,
    minimum_transactions = excluded.minimum_transactions,
    minimum_transactions_fee = excluded.minimum_transactions_fee,
    maximum_transactions = excluded.maximum_transactions,
    maximum_transactions_fee = excluded.maximum_transactions_fee;
END;
$$ LANGUAGE plpgsql;