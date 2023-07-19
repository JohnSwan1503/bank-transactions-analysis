CREATE TYPE transactionType AS ENUM(
    'debit',
    'credit'
);

CREATE TYPE accountType AS ENUM(
    'personal',
    'business',
    'executiveSelect'
);

CREATE TYPE ruleType AS ENUM(
    'activity_min',
    'activity_max',
    'balance'
);

CREATE TYPE feeType AS (
    rule_value numeric,
    fee money
);
