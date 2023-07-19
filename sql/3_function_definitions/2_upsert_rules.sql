CREATE OR REPLACE FUNCTION upsert_rules(
        _rule_year INTEGER,
        _account_type account_type,
        _rule_type ruleType,
        _fee feeType
    ) RETURNS VOID AS $$ BEGIN
INSERT INTO rules (
        rule_year,
        account_type,
        rule_type,
        fee
    )
VALUES (
        _rule_year,
        _account_type,
        _rule_type,
        _fee
    ) ON CONFLICT (rule_year, account_type, rule_type) DO
UPDATE
SET fee = excluded.fee;
END;
$$ LANGUAGE plpgsql;