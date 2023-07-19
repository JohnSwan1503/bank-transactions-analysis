CREATE OR REPLACE FUNCTION generate_transactions(year integer)
    RETURNS TABLE(
        account_id integer,
        transaction_amount money,
        transaction_date date
    )
    AS $$
DECLARE
    account integer;
    t_date date;
    excluded_months int[];
    current_account RECORD;
BEGIN
    FOR current_account IN
    SELECT
        *
    FROM
        accounts LOOP
            excluded_months := ARRAY[(RANDOM() * 11 + 1)::int,(RANDOM() * 11 + 1)::int,(RANDOM() * 11 + 1)::int];
            FOR i IN 1..(current_account.account_id * 150)::int LOOP
                t_date :=(year::text || '-01-01')::date +(RANDOM() *(365 - 1) + 1)::int;
                IF EXTRACT(MONTH FROM t_date) = ANY (excluded_months) THEN
                    CONTINUE;
                END IF;
                account_id := current_account.account_id;
                transaction_amount := CAST(RANDOM() * 400 - 200 AS NUMERIC)::money;
                transaction_date := t_date;
                RETURN NEXT;
            END LOOP;
        END LOOP;
    RETURN;
END;
$$
LANGUAGE plpgsql;

SELECT
    *
FROM
    generate_transactions(2020);

