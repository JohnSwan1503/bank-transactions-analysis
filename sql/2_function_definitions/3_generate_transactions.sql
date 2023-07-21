CREATE OR REPLACE FUNCTION generate_transactions(
    p_transaction_count integer, 
    p_year              integer
) RETURNS TABLE (
    account_id          integer,
    transaction_amount  money,
    transaction_date    date
) LANGUAGE sql
AS $$
    WITH accounts_cte   AS ( SELECT account_id, created_date
                               FROM accounts
                              WHERE EXTRACT( YEAR FROM created_date )::int <= p_year 
    ), transactions_cte AS ( SELECT a.account_id,
                                    a.created_date,
                                    CAST( RANDOM() * 400 - 200 AS NUMERIC )::money AS transaction_amount,
                                    GREATEST( a.created_date, ( '01-01-' || p_year::text )::date ) + ( RANDOM() * 365 )::int AS transaction_date
                               FROM accounts_cte a, LATERAL generate_series( 1, p_transaction_count ) AS _ )
    SELECT t.account_id, 
           t.transaction_amount, 
           t.transaction_date
      FROM transactions_cte t
     WHERE t.transaction_date >= t.created_date
       AND EXTRACT( YEAR FROM t.transaction_date )::int = p_year
     ORDER BY t.transaction_date ASC, t.account_id ASC;
$$;
