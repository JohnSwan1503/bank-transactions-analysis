# Problem_3_of_3 Bank Transactions Analysis
A fun exploration of a SQL code assessment 

The original prompt was to get a year end account balance for a single bank account's transactions for that year,
applying fees each month based on 1 or 2 rules about account activity.

This expands the scope to solve the "year-end account balance after fees" problem for:
 - An arbitrary number of accounts
 - An arbitrary number of account types
 - An arbitrary set of account balance and rules and associated fees. 
    - Fees are determied on an account type basis
    - Fees have begin dates and only the most recent fees, relative to the date of the transaction, are applied.

While also providing transaction and account data generation tools and a means to upsert fee schedules.

There is a `docker-compose.yml` file that initializes the data type, table, function definitions that make this possible.
To reach the solution, just run the `4_data_insertion.sql` and `5_solution.sql` file in that order.

# Process
### Missing Data

#### Step One: Database
The first challenge encountered after the coding challenge was how to deal with the lack of data to work with. I could not see the text of the prompt anymore, nor did I have access to the table of transactions to query an answer from. No problem. 

```yaml
version: "3.1"

services:
  db:
    image: postgres
    restart: always
    hostname: postgres
    environment:
      POSTGRES_PASSWORD: example
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
    logging:
      driver: "json-file"
      options:
        max-size: "200k"
        max-file: "3"
    ports:
      - 5432:5432
```
<sup>_Spin up a postgres db with some boilerplate docker-compose yaml:_</sup>

---
#### Step Two: Transactions
Now I could create a `transactions` table to store the data to derive my solution from. However, since I now can control the table definition, I can take care of one of the requirements from the prompt: keeping track of the transaction types in order to determnine if certain activity penalties should be applied. This is possible to as a step in the solution query, but as it is tracking something with only 2 states, it's free to generate in the table itself, and not worth the legibility cost in the solution logic. Also, to increase the complexity of the challenge now that time was no longer a factor, I decided to expand the scope of the problem: 
> Instead of generating the transactions of a single account for a single year and calculating the final balance with the monthly fees applied, I can generate the transactions arbitrarily many accounts for an arbitrary number of years and calculate the year end balance for any given year within that range.

I pretended that my bank was started Jan-1 2020, so I added a constraint to the transaction_date column as a way to safeguard any transactions from being backdated before that point in time.

```sql
CREATE TYPE transactiontype AS ENUM(
    'debit',
    'credit'
);
```
<sup>_Create a **transactionType** ENUM data type for use in the **transactions** table.:_</sup>

```sql
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

```
<sup>_Create a **transactions** table. Include a stored generated column **transaction_type** to label transaction type and constrain the transaction date to not be before Jan-1, 2020._</sup>

---
#### Step Three: Rules and Account Types
Here is where I begin to really depart from the original scope of the problem as stated in the code assessment. I could not remember what the rules were that determined how to apply penalty fees, nor did I remember what the fee amounts were. I remembered that there was a negative balance fee and some kind of account activity fee that could be conditionally applied depending on the relative or absolute count of transactions crediting the account. Not wanting to just hardcode variables and call it a day, I decided to instead create a rules table that could store different penalties, the conditions that would trigger them, the fees they would incur, and what year to start applying them. 

Then I had a thought: "If I can create any number of rules/penalties, why not create specific types of accounts to determine which penalties are applied and when?" So in addition to a table to store the rules' definitions, I created an accounts table to store the different accounts transacting at the my bank as well as information about what the type of account it is, when it was opened, and the starting balance. To simplify, I decided to make the starting balance a generated field depending on the type of the account.

```sql
CREATE TYPE accounttype AS ENUM(
    'personal',
    'business',
    'dataengineer'
);
```
<sup>_Create an **accountType** ENUM to store the different account type names for use in the **accounts** and **rules** tables._</sup>

```sql
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

```
<sup>_Create an **accounts** table. Include a stored generated column **starting_balance** based on the account type and constrain the **created_on** date to not be before Jan-1, 2020._</sup>

Now that I had a place to hold the accounts and their types, I could start thinking about how I wanted to define the transaction and account balance rules for the bank. I created two new types to define the penalties: 
 - `ruletype` to label if it is an account activty penalty or an account balance penalty and
 - `feetype` to store the limit (or `rule_value`) and the `fee` to pay if that limit is violated
   - For account `balance` rules, the `feeType.rule_value` defines the minimum account balance
   - For account `activity` penalties,
     - a negative `feeType.rule_value` indicates an account inactivity fee
     - a positive `feeType.rule_value` inidates an account overactivity fee

```sql
CREATE TYPE ruletype AS ENUM(
    'activity_min',
    'activity_max',
    'balance'
);

CREATE TYPE feetype AS (
    rule_value numeric,
    fee        money
);

```
<sup>_Create a **ruleType** ENUM and a **feeType** composite type for use in the **rules** table._</sup>

```sql
CREATE TABLE rules (
    rule_year    integer     NOT NULL,
    account_type accounttype NOT NULL,
    rule_type    ruletype    NOT NULL,
    fee          feetype     NOT NULL,
                 CONSTRAINT  rules_pk        PRIMARY KEY (rule_year, account_type, rule_type),
                 CONSTRAINT  rule_year_check CHECK       (rule_year BETWEEN 2020 AND 2030)
);
```
<sup>_Create a **rules** table to store the penalties, their types, fee structure, trigger, starting year, and account type they apply to._</sup>

---
### Generating Data
#### Step One: Creating Semi-Random Accounts 
Now I could **finally** start inserting some data into these tables. However, considering that there would be potentially thousands of records to insert, I did't want to do that manually if I could help it. Luckily sql and plpgsql functions and procedures can do that work for me.

First, to generate an arbitrary number of accounts (with different types) I created `generate_accounts(int, numeric[], date)` to return a table (think: output of a SELECT statement) of account types and starting dates. The function would would accept the following parameters: [^1]
 - `num_accounts` _(integer)_: the number of accounts to generate; required
 - `weights` _(numeric\[3])_: array of weights to defining the relative distribution of account types; optional
   - Order of weights: `personal`, `business`, and `dataengineer`
   - Defaults to an equal distribution \[1, 1, 1]
 - `start_date` _(date)_: date to pass as the account `created_on`; optional
   - Defaults to a different random date between the current date and Jan-1, 2020 for each account being generated.
   - If parameter value is prior to Jan-1, 2020 then the latter of the two dates is used.

```sql
CREATE OR REPLACE FUNCTION array_shift_min(
          numeric[], 
          numeric    DEFAULT NULL
) RETURNS numeric[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::numeric ) 
                                    - MIN( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::numeric[] );
$$;

CREATE OR REPLACE FUNCTION array_shift_min(
          integer[], 
          integer    DEFAULT NULL
) RETURNS integer[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::integer ) 
                                    - MIN( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::integer[] );
$$;

CREATE OR REPLACE FUNCTION array_shift_min(
          money[], 
          money    DEFAULT NULL
) RETURNS money[]
 LANGUAGE sql
STABLE AS $$
    SELECT
          COALESCE( ARRAY( SELECT y + COALESCE( $2, 0.00::money ) 
                                    - MIN( y ) OVER()
                             FROM UNNEST( $1 ) AS y ), ARRAY[]::money[] );
$$;

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
```
<sup>Create a new functions **array_scale** [^1]</sup> 

```sql
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
```
<sup>Create a new function, **generate_accounts** that returns a table by utilizing the **RETURN NEXT** plpgsql pattern</sup>

#### Step Two: Generating Random Transactions
Next, to generate some transaction data, I created `generate_transactions(integer, integer)` to return a table of `account_ids`, `transaction_amounts`, and `transaction_dates`. Since this endeavor was sufficiently complex: 
 - I decided to just pick a ranom value in the range -200..200 as the transaction ammount for all transactions. 
 - There is an integer input parameter `year` that defines the year to create transactions for.
 - To randomly incur penalties for no monthly activity, 1 - 2 random months are optionally picked for each account generating transactions.

The two function parameters are as follows:
 - `p_transation_count` _(integer)_: The maximum number of transactions to select
   - Every valid account has `transaction_count` (or 1, whichever is bigger) opportunities to generate a transaction.
   - If for some reason a transaction cannot occur, the loop continues.
 - `p_year` _(integer)_: The year the generated transactions occur in
   - Accounts may not transact before they exist. This negatively affects the to
   - Accounts that were not yet started by the input parameter, `_year` are not considered in {valid accounts}

```sql
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
```
<sup>Create a new function **generate_transactions** that returns a table by looping through all valid accounts and then utilizing the RETURN NEXT plpgsql pattern</sup>

#### Step Three: Making Rules
Finally, I created a function to populate the `rules` table with some `accountType` specific penalties. I decided that because I don't want to have contradictory rules for any given year, I would need to utilize the UPSERT sql pattern where whenever there is a collision (i.e. when the input year, account_type, and rule_type is already in the `rules` table) then update the fee value instead of inserting a new record.

```sql
CREATE OR REPLACE FUNCTION upsert_rules(
          rules.rule_year%TYPE,
          rules.account_type%TYPE,
          rules.rule_type%TYPE,
          rules.fee%TYPE
) RETURNS VOID 
LANGUAGE  plpgsql 
VOLATILE  AS $$ 
    BEGIN
        INSERT INTO rules 
            ( rule_year
            , account_type
            , rule_type
            , fee )
        VALUES 
            ( $1
            , $2
            , $3
            , $4 ) 
        ON CONFLICT 
            ( rule_year
            , account_type
            , rule_type ) 
        DO UPDATE SET fee = excluded.fee;
    END;
$$;
```

<sup>Create a new function **upsert_rules** to perform the INSERT UPDATE ON CONFLICT sql command.</sup>

---
### Finding a Solution
Finally I was ready to attempt a solution. There was an added level of difficulty as fees could compound and trigger other fees. In order to reflect this behavior I had to employ a pretty long and drawn out sql statement that utilized multiple lateral joins in order to get the self-referencial, conditional, cumulative summation of the fees just right.

I also broke out a sql function to capture the edgecase when a particular type of account is exempt (doe not yet have any fees defined yet) from a particular type of penalty. This function populates those missing values with a null value and makes interacting with that year's set of rules stable as there will always be 3 penalty rule options to check for each type of account. 

```sql

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
```

Thank you for making it this far.

[^1]: Account types are determined randomly. The `weights` array is transformed using some user-defined sql and plpgsql functions so that the values sum to 1. In the case that there are one or more negative values passed to the `weights` parameter, array values `a` have `y` added to them where `y = 0 - min(weights)`. To keep function logic maintainable and legible, I created a module of utility functions to manipulate arrays. This was additionally in order to avoid having to write sql code like, `SELECT COALESCE((SELECT SUM(x) FROM UNNEST({some_array}) AS x), 0.0)` over and over.
