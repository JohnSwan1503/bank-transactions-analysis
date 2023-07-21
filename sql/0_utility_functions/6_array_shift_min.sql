CREATE OR REPLACE FUNCTION array_shift_min(
          numeric[], 
          numeric    DEFAULT NULL
) RETURNS numeric[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::numeric ) 
                                    - MIN( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::numeric[] );
$$;

CREATE OR REPLACE FUNCTION array_shift_min(
          integer[], 
          integer    DEFAULT NULL
) RETURNS integer[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::integer ) 
                                    - MIN( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::integer[] );
$$;

CREATE OR REPLACE FUNCTION array_shift_min(
          money[], 
          money    DEFAULT NULL
) RETURNS money[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::money ) 
                                    - MIN( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::money[] );
$$;