CREATE TYPE accounttype AS ENUM(
    'personal',
    'business',
    'dataengineer'
);

CREATE TABLE accounts (
    account_id       serial      NOT NULL,
    account_type     accounttype NOT NULL,
    created_date     date        NOT NULL,
                     CONSTRAINT  account_id_pk      PRIMARY KEY (account_id),
                     CONSTRAINT  created_date_check CHECK       (created_date BETWEEN '2019-01-01'::date AND '2030-12-31'::date)
);

CREATE OR REPLACE FUNCTION generate_starting_balance(
             accounts.account_type%TYPE
)   RETURNS  transactions::transaction_amount%TYPE
    LANGUAGE sql 
IMMUTABLE AS $$
    SELECT
        CASE account_type
            WHEN 'personal'::accounttype     THEN '1000.00'::transactions::transaction_amount%TYPE
            WHEN 'business'::accounttype     THEN '10000.00'::transactions::transaction_amount%TYPE
            WHEN 'dataengineer'::accounttype THEN '100000.00'::transactions::transaction_amount%TYPE
        END;
$$;

ALTER  TABLE accounts 
  ADD COLUMN starting_balance money NOT NULL GENERATED ALWAYS AS (generate_starting_balance(account_type)) STORED;

CREATE TYPE newaccount AS (
    acount_type  accounttype,
    created_date date
);
