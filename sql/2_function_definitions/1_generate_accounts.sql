CREATE OR REPLACE FUNCTION generate_accounts(
    p_num_accounts integer, 
    p_weights      numeric[3]  DEFAULT ARRAY[1.0, 1.0, 1.0], 
    p_start_date   date        DEFAULT NULL
) RETURNS TABLE (
    account_type   accounttype,
    created_date   date
) LANGUAGE sql 
AS $$
    WITH weights_cte AS ( SELECT CASE WHEN ARRAY_LENGTH( p_weights, 1 ) < 3
                                      THEN ARRAY_SCALE( ARRAY[1.0, 1.0, 1.0], 1.0 )
                                      ELSE ARRAY_SCALE( p_weights ) END AS weights )
    SELECT CASE WHEN RANDOM() < w.weights[1]                THEN 'personal'::accounttype
                WHEN RANDOM() < w.weights[1] + w.weights[2] THEN 'business'::accounttype
                ELSE 'dataengineer'::accounttype END AS account_type,
           CASE WHEN p_start_date IS NULL 
                THEN '01-01-2020'::date + ( RANDOM() * ( CURRENT_DATE - '01-01-2020'::date) )::int
                ELSE GREATEST( p_start_date, '01-01-2020'::date ) END AS created_date
      FROM weights_cte w, LATERAL generate_series(1, p_num_accounts) AS _;
$$;
