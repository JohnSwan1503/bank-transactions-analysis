CREATE OR REPLACE FUNCTION calculate_year_end_balances () RETURNS TABLE (account_id INTEGER, end_of_year_balance MONEY) AS $$
DECLARE month INTEGER;
running_balance MONEY;
monthly_transactions INTEGER;
rule rules %ROWTYPE;
current_account RECORD;
transaction RECORD;
BEGIN
SELECT INTO rule *
FROM rules
WHERE rule_year = 2023;
FOR current_account IN
SELECT *
FROM accounts LOOP running_balance := current_account.account_balance_jan1;
FOR month IN 1..12 LOOP FOR transaction IN (
    SELECT t.transaction_amount
    FROM transactions t
    WHERE t.account_id = current_account.account_id
        AND EXTRACT(
            MONTH
            FROM t.transaction_date
        ) = month
        AND EXTRACT(
            YEAR
            FROM t.transaction_date
        ) = 2023
    ORDER BY t.transaction_date
) LOOP running_balance := running_balance + transaction.transaction_amount;
END LOOP;
-- Apply the fees for the month if necessary
IF running_balance < MONEY '0.00' THEN running_balance := running_balance - rule.overdraft_fee;
END IF;
SELECT INTO monthly_transactions COUNT(*)
FROM transactions t
WHERE t.account_id = current_account.account_id
    AND EXTRACT(
        MONTH
        FROM t.transaction_date
    ) = month
    AND EXTRACT(
        YEAR
        FROM t.transaction_date
    ) = 2023;
IF monthly_transactions < rule.minimum_transactions THEN running_balance := running_balance - rule.minimum_transactions_fee;
ELSIF monthly_transactions > rule.maximum_transactions THEN running_balance := running_balance - rule.maximum_transactions_fee;
END IF;
END LOOP;
calculate_year_end_balances.account_id := current_account.account_id;
calculate_year_end_balances.end_of_year_balance := running_balance;
RETURN NEXT;
END LOOP;
RETURN;
END;
$$ LANGUAGE plpgsql;