CREATE OR REPLACE FUNCTION generate_accounts(
    num_accounts    integer, 
    weights         numeric[3]  DEFAULT ARRAY[1.0, 1.0, 1.0], 
    p_start_date    date        DEFAULT NULL
) RETURNS TABLE (
    account_type accountType,
    created_date date
) LANGUAGE plpgsql AS $$
BEGIN
    IF ARRAY_LENGTH(weights, 1) < 3 THEN
        RAISE EXCEPTION 'Weights array must have 3 elements';
    END IF;
    weights := ARRAY_SCALE(weights, 1.0);
    FOR EACH IN 1..num_accounts LOOP
        account_type :=(
            SELECT
                CASE WHEN RANDOM() < weights[1] THEN
                    'personal'::accountType
                WHEN RANDOM() < weights[1] + weights[2] THEN
                    'business'::accountType
                ELSE
                    'dataengineer'::accountType
                END);
        IF p_start_date IS NULL THEN
	    created_date := '01-01-2020'::date +(RANDOM() *(CURRENT_DATE -
		'01-01-2020'::date))::int;
        ELSE
            created_date := GREATEST(p_start_date, '01-01-2020'::date);
        END IF;
        RETURN NEXT;
    END LOOP;
END;
$$;
