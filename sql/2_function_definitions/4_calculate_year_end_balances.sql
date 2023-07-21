
CREATE OR REPLACE FUNCTION get_penalties(
          integer
) RETURNS TABLE (
    account_type accounttype,
    fees         feetype[]
) LANGUAGE sql
AS $$
    WITH rules_cte AS ( SELECT x.account_type,
                               y.rule_type,
                               r.fee
                          FROM UNNEST( ARRAY[ 'personal'::accounttype
                                            , 'business'::accounttype
                                            , 'dataengineer'::accounttype ] ) AS x ( account_type )
                    CROSS JOIN UNNEST( ARRAY[ 'activity_min'::ruletype
                                            , 'activity_max'::ruletype
                                            , 'balance'::ruletype ] ) AS y ( rule_type )
                     LEFT JOIN ( SELECT * 
                                   FROM rules 
                                  WHERE rule_year = $1 ) r 
                            ON x.account_type = r.account_type AND 
                               y.rule_type = r.rule_type
                      ORDER BY x.account_type, y.rule_type, r.fee )
    SELECT r_cte.account_type,
           ARRAY_AGG( r_cte.fee ) AS fees
      FROM rules_cte AS r_cte
  GROUP BY r_cte.account_type
  ORDER BY r_cte.account_type;
$$;

CREATE OR REPLACE FUNCTION calculate_year_end_balances(
          integer
) RETURNS TABLE (
    account_id          integer,
    year_end_balance    money
) LANGUAGE sql
    AS $$
    WITH rules_cte AS (
        SELECT r.account_type,
               r.fees
            FROM get_penalties( 2020 ) r)
     , transactions_cte AS ( SELECT account_id, 
                                    transaction_id,
                                    transaction_type,
                                    transaction_date,
                                    EXTRACT( MONTH FROM transaction_date ) as transaction_month, 
                                    transaction_amount,
                                    SUM( transaction_amount ) OVER rolling_sum AS running_balance,
                                    SUM( 1 )   OVER rolling_sum AS transaction_count,
                                    COALESCE ( SUM( 1 ) FILTER ( WHERE transaction_type = 'debit'::transactiontype ) OVER rolling_sum, 0 ) AS debit_count
                              FROM transactions
                            WINDOW rolling_sum AS ( PARTITION BY account_id, EXTRACT( MONTH FROM transaction_date )
                                                        ORDER BY transaction_date 
                                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )
                          ORDER BY account_id, transaction_date ASC )
    , monthly_balances AS ( SELECT DISTINCT ON ( t.account_id, t.transaction_month )
                                   t.account_id,
                                   a.account_type,
                                   a.starting_balance,
                                   t.transaction_month,
                                   t.running_balance AS monthly_balance,
                                   t.transaction_count,
                                   t.debit_count
                              FROM transactions_cte t 
                              JOIN accounts a USING ( account_id )
                          ORDER BY t.account_id, t.transaction_month, t.transaction_count DESC )
    , monthly_activity_fees AS ( SELECT m.account_id,
                                        m.account_type,
                                        m.transaction_month,
                                        m.starting_balance,
                                        m.starting_balance + SUM( m.monthly_balance 
                                                                  - fees.activity_min_fee
                                                                  - fees.activity_max_fee ) OVER monthly_running_window AS running_balance_with_fees
                                   FROM monthly_balances m
                              LEFT JOIN rules_cte r USING ( account_type ),
                              LATERAL ( SELECT CASE WHEN r.fees[1] IS NULL OR m.transaction_count > r.fees[1].rule_value THEN 0.00::money
                                                    ELSE r.fees[1].fee END AS activity_min_fee,
                                               CASE WHEN r.fees[2] IS NULL OR m.transaction_count < r.fees[2].rule_value THEN 0.00::money
                                                    WHEN m.transaction_count > r.fees[2].rule_value AND m.debit_count > m.transaction_count * 0.5
                                                    THEN r.fees[2].fee
                                                    ELSE 0.00::money END AS activity_max_fee ) AS fees
                                 WINDOW monthly_running_window AS ( PARTITION BY m.account_id 
                                                                        ORDER BY m.transaction_month ASC 
                                                                   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )
                               ORDER BY m.account_id, m.transaction_month )
    , balance_fees AS ( SELECT maf.account_id, 
                               maf.account_type,
                               maf.transaction_month,
                               maf.running_balance_with_fees AS running_balance_with_activity_fees,
                               maf.running_balance_with_fees - SUM(fees.balance_fee) OVER monthly_running_window AS running_balance_with_fees
                          FROM monthly_activity_fees maf,
                       LATERAL ( SELECT CASE WHEN maf.running_balance_with_fees < r.fees[3].rule_value::money 
                                             THEN r.fees[3].fee 
                                             ELSE 0.00::money
                                         END AS balance_fee 
                                   FROM rules_cte r
                                  WHERE maf.account_type = r.account_type ) AS fees
                        WINDOW monthly_running_window AS ( PARTITION BY maf.account_id 
                                                               ORDER BY maf.transaction_month ASC 
                                                          RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )
                      ORDER BY maf.account_id, maf.transaction_month )
    SELECT DISTINCT ON (bf.account_id)
           bf.account_id,
           bf.running_balance_with_fees - SUM(fees.final_fee) OVER monthly_running_window AS year_end_balance
      FROM balance_fees bf
      JOIN rules_cte r USING ( account_type ),
   LATERAL ( SELECT CASE WHEN bf.running_balance_with_fees < r.fees[3].rule_value::money 
                         THEN r.fees[3].fee 
                         ELSE 0.00::money
                     END AS final_fee ) AS fees
    WINDOW monthly_running_window AS ( PARTITION BY bf.account_id 
                                           ORDER BY bf.transaction_month ASC   
                                      RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )
  ORDER BY bf.account_id, bf.transaction_month DESC;
$$;