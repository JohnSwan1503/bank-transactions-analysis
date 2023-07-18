CREATE OR REPLACE FUNCTION generate_transactions(year INTEGER) RETURNS TABLE (
        account_id INTEGER,
        transaction_amount MONEY,
        transaction_date DATE
    ) AS $$
DECLARE account INTEGER;
t_date DATE;
excluded_months INT [];
current_account RECORD;
BEGIN FOR current_account IN
SELECT *
FROM accounts LOOP excluded_months := ARRAY [
      (random()*11 + 1)::int,
      (random()*11 + 1)::int,
      (random()*11 + 1)::int
    ];
FOR i IN 1..(current_account.account_id * 150)::INT LOOP t_date := (year::text || '-01-01')::DATE + (random() * (365 - 1) + 1)::INT;
IF extract(
    MONTH
    FROM t_date
) = ANY(excluded_months) THEN CONTINUE;
END IF;
account_id := current_account.account_id;
transaction_amount := CAST(random() * 400 - 200 AS NUMERIC)::MONEY;
transaction_date := t_date;
RETURN NEXT;
END LOOP;
END LOOP;
RETURN;
END;
$$ LANGUAGE plpgsql;