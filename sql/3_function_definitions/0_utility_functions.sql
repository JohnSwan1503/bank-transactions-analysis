CREATE OR REPLACE FUNCTION array_abs(arr numeric[])
    RETURNS numeric[]
    LANGUAGE sql
    AS $$
    SELECT
        ARRAY(
            SELECT
                ABS(x)
            FROM
                UNNEST(arr) AS x);
$$;

CREATE OR REPLACE FUNCTION array_sum(arr numeric[], _start integer DEFAULT 1, _stop integer DEFAULT NULL)
    RETURNS numeric
    LANGUAGE sql
    AS $$
    SELECT
        COALESCE((
            SELECT
                SUM(x)
            FROM UNNEST(arr[_start : COALESCE(_stop, ARRAY_LENGTH(arr, 1))]) AS x), 0.0);
$$;

CREATE OR REPLACE FUNCTION array_max(arr numeric[])
    RETURNS numeric
    LANGUAGE sql
    AS $$
    SELECT
        COALESCE((
            SELECT
                MAX(x)
            FROM UNNEST(arr) AS x), 0.0);
$$;

CREATE OR REPLACE FUNCTION array_min(arr numeric[])
    RETURNS numeric
    LANGUAGE sql
    AS $$
    SELECT
        COALESCE((
            SELECT
                MIN(x)
            FROM UNNEST(arr) AS x), 0.0);
$$;

CREATE OR REPLACE FUNCTION array_shift_min(arr numeric[], x numeric DEFAULT NULL)
    RETURNS numeric[]
    LANGUAGE sql
    AS $$
    SELECT
        COALESCE(ARRAY(
                SELECT
                    y + COALESCE(x, 0) - MIN(y) OVER()
                FROM UNNEST(arr) AS y), ARRAY[]::numeric[]);
$$;

CREATE OR REPLACE FUNCTION array_shift_max(arr numeric[], x numeric DEFAULT NULL)
    RETURNS numeric[]
    LANGUAGE sql
    AS $$
    SELECT
        COALESCE(ARRAY(
                SELECT
                    y + COALESCE(x, 0) - MAX(y) OVER()
                FROM UNNEST(arr) AS y), ARRAY[]::numeric[]);
$$;

CREATE OR REPLACE FUNCTION array_scale(arr numeric[], x numeric DEFAULT 1)
    RETURNS numeric[]
    AS $$
DECLARE
    y numeric;
BEGIN
    arr := array_shift_min(arr, GREATEST(array_min(arr), 0.0));
    RAISE NOTICE 'arr: %', arr;
    y := array_sum(arr);
    IF y = 0 THEN
        RETURN ARRAY (
            SELECT
                x / ARRAY_LENGTH(arr, 1)
            FROM
                UNNEST(arr) AS x);
    ELSE
        arr := ARRAY (
            SELECT
                z * x / y
            FROM
                UNNEST(arr) AS z);
        arr[1] = arr[1] + x - array_sum(arr);
        RETURN arr;
    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT
    array_sum(ARRAY[1, 2, 3, 4, 5]);

