CREATE OR REPLACE FUNCTION generate_transactions(transaction_count integer, _year integer)
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
    transaction_count := transaction_count / GREATEST((
        SELECT
            COUNT(*)
        FROM accounts
        WHERE
            EXTRACT(YEAR FROM created_on)::int <= _year)::int, 1);
    FOR current_account IN
    SELECT
        *
    FROM
        accounts
    WHERE
        EXTRACT(YEAR FROM created_on)::int = _year LOOP
            excluded_months := ARRAY[(RANDOM() * 24)::int,(RANDOM() * 24)::int];
            FOR i IN 1..transaction_count::int LOOP
		t_date := GREATEST(current_account.created_on,('01-01-' ||
		    _year::text)::date) +(RANDOM() *(('12-31-' || _year::text)::date -
		    GREATEST(current_account.created_on,('01-01-' ||
		    _year::text)::date)))::int;
                IF EXTRACT(MONTH FROM t_date) = ANY (excluded_months) OR t_date < current_account.created_on THEN
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
