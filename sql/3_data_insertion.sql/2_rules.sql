
SELECT upsert_rules( 2020
                   , 'personal'::accounttype
                   , 'balance'::ruletype
                   , ( 200.00 , 50.00::money ) );

SELECT upsert_rules( 2020
                   , 'business'::accounttype
                   , 'activity_min'::ruletype
                   , ( 100.00 , 100.00::money ) );
                   
SELECT upsert_rules( 2020
                   , 'business'::accounttype
                   , 'activity_max'::ruletype
                   , ( 100.00 , 100.00::money ) );