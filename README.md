# Problem_3_of_3
A fun exploration of a SQL code assessment 

The original prompt was to get a year end account balance for a single bank account's transactions for that year,
applying fees each month based on 1 or 2 rules about account activity.

This expands the scope to solve the "year-end account balance after fees" problem for:
 * An arbitrary number of accounts
 * An arbitrary set of rules for the given year
While also providing transaction and account data generation tools.

There is a dockerfile that initializes the data type, table, function definitions that make this possible.
To reach the solution, just run the `4_data_insertion.sql` and `5_solution.sql` file in that order.

#TODO
 - Better readme
 - New account generation function
 - Update the rules table and the upsert_rules, generate_transactions, calculate_year_end_balances functions to account for different accountTypes