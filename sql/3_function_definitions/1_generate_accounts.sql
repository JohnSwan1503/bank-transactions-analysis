CREATE OR REPLACE FUNCTION generate_accounts(num_accounts integer, weights numeric[3] DEFAULT ARRAY[1.0, 1.0, 1.0])
    RETURNS TABLE(
        account_type accountType)
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    IF ARRAY_LENGTH(weights, 1) < 3 THEN
        RAISE EXCEPTION 'Weights array must have 3 elements';
    END IF;
    weights := array_scale(weights, 1.0);
    FOR EACH IN 1..num_accounts LOOP
        account_type :=(
            SELECT
                CASE WHEN RANDOM() < weights[1] THEN
                    'personal'::accountType
                WHEN RANDOM() < weights[1] + weights[2] THEN
                    'business'::accountType
                ELSE
                    'billionaire'::accountType
                END);
        RETURN NEXT;
    END LOOP;
END;
$$;

