CREATE TYPE transactiontype AS ENUM(
    'debit',
    'credit'
);

CREATE OR REPLACE FUNCTION generate_transaction_type(
    transaction_amount  transactions.transaction_amount%TYPE
) RETURNS transactiontype LANGUAGE sql IMMUTABLE AS $$ 
    SELECT
        CASE 
            WHEN transaction_amount < money '0.00' THEN 'debit'::transactiontype
            ELSE 'credit'::transactiontype
        END;
$$;

CREATE TYPE accounttype AS ENUM(
    'personal',
    'business',
    'dataengineer'
);

CREATE OR REPLACE FUNCTION generate_starting_balance(
    account_type  accounts.account_type%TYPE
) RETURNS money LANGUAGE sql IMMUTABLE AS $$
    SELECT
        CASE account_type
            WHEN 'personal'::accounttype     THEN money '1000.00'
            WHEN 'business'::accounttype     THEN money '10000.00'
            WHEN 'dataengineer'::accounttype THEN money '100000.00'
        END;
$$;    


CREATE TYPE ruletype AS ENUM(
    'activity_min',
    'activity_max',
    'balance'
);

CREATE TYPE feetype AS (
    rule_value numeric,
    fee money
);
