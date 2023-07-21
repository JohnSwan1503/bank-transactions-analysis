CREATE TYPE transactiontype AS ENUM(
    'debit',
    'credit'
);

CREATE TABLE transactions (
    transaction_id      serial          NOT NULL,
    account_id          integer         NOT NULL,
    transaction_date    date            NOT NULL,
    transaction_amount  money           NOT NULL,
                        CONSTRAINT      transaction_id_pk      PRIMARY KEY (transaction_id),
                        CONSTRAINT      transaction_date_check CHECK       (transaction_date BETWEEN '2020-01-01'::date AND '2030-12-31'::date)
);

CREATE OR REPLACE FUNCTION generate_transaction_type(
            transactions.transaction_amount%TYPE
) RETURNS   transactiontype LANGUAGE sql IMMUTABLE AS $$ 
    SELECT
        CASE WHEN $1 < '0.00'::transactions.transaction_amount%TYPE 
             THEN 'debit'::transactiontype
             ELSE 'credit'::transactiontype
        END;
$$;

ALTER TABLE transactions ADD COLUMN 
    transaction_type    transactiontype NOT NULL     GENERATED ALWAYS AS   (generate_transaction_type(transaction_amount)) STORED;
