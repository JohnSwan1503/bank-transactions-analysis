CREATE OR REPLACE FUNCTION upsert_rules(
          rules.rule_year%TYPE,
          rules.account_type%TYPE,
          rules.rule_type%TYPE,
          rules.fee%TYPE
) RETURNS VOID 
LANGUAGE  plpgsql 
VOLATILE  AS $$ 
    BEGIN
        INSERT INTO rules 
            ( rule_year
            , account_type
            , rule_type
            , fee )
        VALUES 
            ( $1
            , $2
            , $3
            , $4 ) 
        ON CONFLICT 
            ( rule_year
            , account_type
            , rule_type ) 
        DO UPDATE SET fee = excluded.fee;
    END;
$$;

