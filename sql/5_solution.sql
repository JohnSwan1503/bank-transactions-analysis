

WITH monthly_transactions AS (
    SELECT 
          t.account_id AS t_account_id,
          EXTRACT(MONTH FROM t.transaction_date) AS t_month,
          SUM(t.transaction_amount) AS balance,
          COUNT(t.transaction_id) AS transaction_count,
          COUNT(t.transaction_id) FILTER (WHERE t.transaction_type = 'debit'::transactiontype) AS debit_count
    FROM transactions t
    WHERE EXTRACT(YEAR FROM t.transaction_date) = 2020
    GROUP BY 2, 1
    ORDER BY 4 desc)

SELECT 
    mt.t_account_id AS account_id,
    sum_balances(ARRAY_AGG(mt.balance),
                 ARRAY_AGG(mt.transaction_count),
                 ARRAY_AGG(mt.debit_count),
                 a.starting_balance, 
                 a.account_type) AS ending_balance,
    a.account_type AS account_type
FROM GENERATE_SERIES(1, 12) AS m(dt)
LEFT JOIN monthly_transactions mt ON m.dt = mt.t_month
JOIN accounts a 
ON mt.t_account_id = a.account_id
GROUP BY mt.t_account_id, 
         a.account_type, 
         a.starting_balance

