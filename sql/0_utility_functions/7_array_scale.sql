
CREATE OR REPLACE FUNCTION array_scale(
          numeric[], 
          numeric    DEFAULT 1.00::numeric
) RETURNS numeric[]
 LANGUAGE plpgsql
STABLE AS $$
    DECLARE y numeric;
    BEGIN
        $1:= array_shift_min( $1, GREATEST( array_min( $1 ), 0.00::numeric ) );
        y := array_sum($1);

        CASE WHEN y = 0 
             THEN RETURN ARRAY ( SELECT x / ARRAY_LENGTH( $1, 1 )
                                   FROM UNNEST( $1 ) AS x );

             ELSE $1:=   ARRAY ( SELECT x * $2 / y
                                   FROM UNNEST( $1 ) AS x );

         $1[ 1 ] = $1[ 1 ] 
                 + $2 
                 - array_sum( $1 );

        RETURN $1;
    END;
$$;
