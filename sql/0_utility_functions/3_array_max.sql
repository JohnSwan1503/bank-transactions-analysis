CREATE OR REPLACE FUNCTION array_max(
          numeric[]
) RETURNS numeric
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ( SELECT MAX( x )
                        FROM UNNEST( $1 ) AS x ), 0.00::numeric );
$$;

CREATE OR REPLACE FUNCTION array_max(
          integer[]
) RETURNS integer
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ( SELECT MAX( x )
                        FROM UNNEST( $1 ) AS x ), 0.00::integer );
$$;

CREATE OR REPLACE FUNCTION array_max(
          money[]
) RETURNS money
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ( SELECT MAX( x )
                        FROM UNNEST( $1 ) AS x ), 0.00::money );
$$;