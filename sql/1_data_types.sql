CREATE TYPE transactionType AS ENUM(
    'debit',
    'credit'
);

CREATE TYPE accountType AS ENUM(
    'personal',
    'business',
    'billionaire'
);

CREATE TYPE ruleType AS ENUM(
    'activity_max',
    'activity_min',
    'balance'
);

CREATE TYPE feeType AS (
    rule_valu numeric,
    fee money
);

