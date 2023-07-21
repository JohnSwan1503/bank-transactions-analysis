CREATE TYPE ruletype AS ENUM(
    'activity_min',
    'activity_max',
    'balance'
);

CREATE TYPE feetype AS (
    rule_value numeric,
    fee        money
);

CREATE TABLE rules (
    rule_year    integer     NOT NULL,
    account_type accounttype NOT NULL,
    rule_type    ruletype    NOT NULL,
    fee          feetype     NOT NULL,
                 CONSTRAINT  rules_pk        PRIMARY KEY (rule_year, account_type, rule_type),
                 CONSTRAINT  rule_year_check CHECK       (rule_year BETWEEN 2020 AND 2030)
);