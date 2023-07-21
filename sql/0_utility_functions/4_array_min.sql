CREATE OR REPLACE FUNCTION array_min(
          numeric[]
) RETURNS numeric
 LANGUAGE sql
STABLE AS  $$
    SELECT
          COALESCE( ( SELECT MAX( x )
                        FROM UNNEST( $1 ) AS x ), 0.00::numeric );
$$;

CREATE OR REPLACE FUNCTION array_min(
          integer[]
) RETURNS integer
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ( SELECT MAX( x )
                        FROM UNNEST( $1 ) AS x ), 0.00::integer );
$$;

CREATE OR REPLACE FUNCTION array_min(
          money[]
) RETURNS money
 LANGUAGE sql
STABLE AS  $$
    SELECT
          COALESCE( ( SELECT MAX( x )
                        FROM UNNEST( $1 ) AS x ), 0.00::money );
$$;