CREATE OR REPLACE FUNCTION array_abs( 
          numeric[] 
) RETURNS numeric[]
 LANGUAGE sql
AS STABLE $$
    SELECT
          ARRAY( SELECT ABS( x )
                   FROM UNNEST( arr ) 
                     AS x );
$$;

CREATE OR REPLACE FUNCTION array_abs( 
          integer[] 
) RETURNS integer[]
 LANGUAGE sql
AS STABLE $$
    SELECT
          ARRAY( SELECT ABS( x )
                   FROM UNNEST( arr ) 
                     AS x );
$$;

CREATE OR REPLACE FUNCTION array_abs( 
          money[] 
) RETURNS money[]
 LANGUAGE sql
AS STABLE $$
    SELECT
          ARRAY( SELECT ABS( x )
                   FROM UNNEST( arr ) 
                     AS x );
$$;