CREATE OR REPLACE FUNCTION array_shift_max(
          numeric[], 
          numeric    DEFAULT NULL
) RETURNS numeric[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::numeric ) 
                                    - MAX( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::numeric[] );
$$;


CREATE OR REPLACE FUNCTION array_shift_max(
          integer[], 
          integer    DEFAULT NULL
) RETURNS integer[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::integer ) 
                                    - MAX( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::integer[] );
$$;

CREATE OR REPLACE FUNCTION array_shift_max(
          money[], 
          money    DEFAULT NULL
) RETURNS money[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::money ) 
                                    - MAX( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::money[] );
$$;