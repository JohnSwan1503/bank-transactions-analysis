CREATE OR REPLACE FUNCTION upsert_rules(
    p_rule_year     rules.rule_year%TYPE,
    p_account_type  rules.account_type%TYPE,
    p_rule_type     rules.rule_type%TYPE,
    p_fee           rules.fee%TYPE
) RETURNS VOID LANGUAGE plpgsql STABLE AS $$ 
    BEGIN
        INSERT INTO rules ( 
        rule_year
        , account_type
        , rule_type
        , fee)
        VALUES ( 
        p_rule_year
        , p_account_type
        , p_rule_type
        , p_fee) 
        ON CONFLICT ( 
        rule_year
        , account_type
        , rule_type) 
        DO 
        UPDATE
        SET    fee = excluded.fee;
    END;
$$;