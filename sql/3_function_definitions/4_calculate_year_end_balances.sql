
CREATE OR REPLACE FUNCTION get_penalty(
    integer,
    accounttype,
    ruletype
) RETURNS feetype LANGUAGE sql IMMUTABLE AS $$
    SELECT
        r.fee
    FROM
        rules r
    WHERE
        r.rule_year <= $1 AND
        r.account_type = $2 AND
        r.rule_type = $3;
$$;

CREATE OR REPLACE FUNCTION sum_balances(
    money[], 
    bigint[],
    bigint[],
    money, 
    accounttype,
    integer
)   RETURNS money AS $$
    DECLARE
        _sum money;
        _fee feetype;
    BEGIN
        _sum := $4;
    FOR i IN 1..ARRAY_LENGTH($1, 1) LOOP
        _sum := _sum + $1[i];

        _fee := COALESCE(get_penalty($6, $5, 'activity_min'::ruletype), NULL);

        IF _fee IS NOT NULL AND $2[i] < _fee.rule_value THEN
            _sum := _sum - _fee.fee;
        END IF;

        _fee := COALESCE(get_penalty($6, $5, 'activity_max'::ruletype), NULL);
        
        IF _fee IS NOT NULL AND $2[i] > _fee.rule_value THEN
            _sum := _sum - _fee.fee;
        END IF;

        _fee := COALESCE(get_penalty($6, $5, 'balance'::ruletype), NULL);

        IF _fee IS NOT NULL AND _sum < _fee.rule_value THEN
            _sum := _sum - _fee.fee;
        END IF;
    END LOOP;
    RETURN _sum;
    END;
$$ LANGUAGE plpgsql;