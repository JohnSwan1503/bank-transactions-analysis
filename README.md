# Problem_3_of_3
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
Now I can create a table to store the transactions data to derive my solution from. However, since I now can control the table definition, I can take care of one of the requirements from the prompt: keeping track of the transaction types in order to determnine if certain activity penalties should be applied. This is possible to as a step in the solution query, but as it is tracking something with only 2 states, it's free to generate in the table itself, and not worth the legibility cost in the solution logic. 

Also, to increase the complexity of the challenge now that time is no longer a factor, I decided to expand the scope of the problem: instead of generating the transactions of a single account for a single year and calculating the final balance with the monthly fees applied, I can generate the transactions arbitrarily many accounts for an arbitrary number of years and calculate the year end balance for any given year within that range. I'll pretend that this bank was started Jan-1 2020, so I added a constraint to the transaction_date column as a way to safeguard any transactions from being backdated before that point in time.

<sup>_Create a **transactionType** ENUM data type for use in the **transactions** table.:_</sup>

```sql
CREATE TYPE transactionType AS ENUM(
    'debit',
    'credit'
);
```
<sup>_Create a **transactionType** ENUM data type for use in the **transactions** table.:_</sup>

```sql
CREATE TABLE IF NOT EXISTS transactions(
    transaction_id serial NOT NULL PRIMARY KEY,
    account_id integer NOT NULL FOREIGN KEY REFERENCES accounts(account_id), -- Some foreshadowing for later
    transaction_date date NOT NULL CHECK (transaction_date >= '01-01-2020'::date), --
    transaction_amount money NOT NULL,
    transaction_type transactionType GENERATED ALWAYS AS (
        CASE WHEN transaction_amount < money '0.00' THEN
            'debit'::transactionType
        ELSE
            'credit'::transactionType
        END ) STORED
);
```
<sup>_Create a **transactions** table. Include a stored generated column **transaction_type** to label transaction type and constrain the transaction date to not be before Jan-1, 2020._</sup>

---
#### Step Three: Rules and Account Types
Here is where I begin to really depart from the original scope of the problem as stated in the code assessment. I could not remember what the rules were that determined how to apply penalty fees, nor did I remember what the fee amounts were. I remembered that there was a negative balance fee and some kind of account activity fee that could be conditionally applied depending on the relative or absolute count of transactions crediting the account. Not wanting to just hardcode variables and call it a day, I decided to instead create a rules table that could store different penalties, the conditions that would trigger them, the fees they would incur, and what year to start applying them. 

Then I had a thought: "If I can create any number of rules/penalties, why not create specific types of accounts to determine which penalties are applied and when?" So in addition to a table to store the rules' definitions, I created an accounts table to store the different accounts transacting at the my bank as well as information about what the type of account it is, when it was opened, and the starting balance. To simplify, I decided to make the starting balance a generated field depending on the type of the account.

```sql
CREATE TYPE accountType AS ENUM(
    'personal',
    'business',
    'executiveSelect',
);
```
<sup>_Create an **accountType** ENUM to store the different account type names for use in the **accounts** and **rules** tables._</sup>

```sql
CREATE TABLE IF NOT EXISTS accounts(
    account_id integer NOT NULL PRIMARY KEY,
    account_type accountType NOT NULL DEFAULT 'personal' ::accountType,
    created_on date NOT NULL CHECK (created_on >= '01-01-2020'::date),
    starting_balance GENERATED ALWAYS AS (
        CASE WHEN account_type = 'personal'::accountType THEN money '1000.00'
            WHEN account_type = 'business'::accountType THEN money '10000.00'
            WHEN account_type = 'executiveSelect'::accountType THEN money '10000.00'
        END) STORED
);
```
<sup>_Create an **accounts** table. Include a stored generated column **starting_balance** based on the account type and constrain the **created_on** date to not be before Jan-1, 2020._</sup>

Now that I had a place to hold the accounts and their types, I could start thinking about how I wanted to define the transaction and account balance rules for the bank. I created two new types to define the penalties: 
 - `ruleType` to label if it is an account activty penalty or an account balance penalty and
 - `feeType` to store the limit (or `rule_value`) and the `fee` to pay if that limit is violated
   - For account `balance` rules, the `feeType.rule_value` defines the minimum account balance
   - For account `activity` penalties,
     - a negative `feeType.rule_value` indicates an account inactivity fee
     - a positive `feeType.rule_value` inidates an account overactivity fee
     - 



# TODO
 - ~~More informative README file~~
 - ~~New account generation function~~
 - Update the ~~rules table~~ and the ~~upsert_rules,~~ ~~generate_transactions,~~ calculate_year_end_balances functions to account for different accountTypes and different begin dates for fees.
 - Dockerfile for orchestration, 
