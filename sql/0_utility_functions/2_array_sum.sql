CREATE OR REPLACE FUNCTION array_sum(
          numeric[],
          integer    DEFAULT 1, 
          integer    DEFAULT NULL
) RETURNS numeric
 LANGUAGE sql
STABLE AS  $$
    SELECT
          COALESCE( ( SELECT SUM(x)
                        FROM UNNEST( $1[ $2 : COALESCE( $3, ARRAY_LENGTH( $1, 1 )) ] ) 
                          AS x ), 0.00::numeric );
$$;

CREATE OR REPLACE FUNCTION array_sum(
          integer[],
          integer    DEFAULT 1, 
          integer    DEFAULT NULL
) RETURNS money
 LANGUAGE sql
STABLE AS  $$
    SELECT
          COALESCE( ( SELECT SUM(x)
                        FROM UNNEST( $1[ $2 : COALESCE( $3, ARRAY_LENGTH( $1, 1 )) ] ) 
                          AS x ), 0.00::integer );
$$;

CREATE OR REPLACE FUNCTION array_sum(
          money[],
          integer    DEFAULT 1, 
          integer    DEFAULT NULL
) RETURNS money
 LANGUAGE sql
STABLE AS  $$
    SELECT
          COALESCE( ( SELECT SUM(x)
                        FROM UNNEST( $1[ $2 : COALESCE( $3, ARRAY_LENGTH( $1, 1 )) ] ) 
                          AS x ), 0.00::money );
$$;