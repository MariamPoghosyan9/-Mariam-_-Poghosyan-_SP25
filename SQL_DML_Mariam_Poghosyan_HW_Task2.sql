--task 2
-- 1️Create ‘table_to_delete’ and Fill It time 15 sec
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

-- 2️Check Space Consumption BEFORE Deletion
SELECT *, pg_size_pretty(total_bytes) AS total,
             pg_size_pretty(index_bytes) AS index,
             pg_size_pretty(toast_bytes) AS toast,
             pg_size_pretty(table_bytes) AS table
FROM ( SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
              FROM (SELECT c.oid, nspname AS table_schema,
                               relname AS table_name,
                               c.reltuples AS row_estimate,
                               pg_total_relation_size(c.oid) AS total_bytes,
                               pg_indexes_size(c.oid) AS index_bytes,
                               pg_total_relation_size(reltoastrelid) AS toast_bytes
                      FROM pg_class c
                      LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                      WHERE relkind = 'r'
                    ) a
           ) a
WHERE table_name LIKE '%table_to_delete%';

-- 3️ DELETE 1/3 of the Rows
-- a) Note how much time it takes to perform this DELETE statement time 11 sec 56msec
EXPLAIN ANALYZE DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;

-- b) Lookup how much space this table consumes after DELETE
SELECT *, pg_size_pretty(total_bytes) AS total,
             pg_size_pretty(index_bytes) AS index,
             pg_size_pretty(toast_bytes) AS toast,
             pg_size_pretty(table_bytes) AS table
FROM ( SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
              FROM (SELECT c.oid, nspname AS table_schema,
                               relname AS table_name,
                               c.reltuples AS row_estimate,
                               pg_total_relation_size(c.oid) AS total_bytes,
                               pg_indexes_size(c.oid) AS index_bytes,
                               pg_total_relation_size(reltoastrelid) AS toast_bytes
                      FROM pg_class c
                      LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                      WHERE relkind = 'r'
                    ) a
           ) a
WHERE table_name LIKE '%table_to_delete%';

-- c) Perform VACUUM FULL VERBOSE time 5 sec
VACUUM FULL VERBOSE table_to_delete;

-- d) Check space consumption again after VACUUM FULL
SELECT *, pg_size_pretty(total_bytes) AS total,
             pg_size_pretty(index_bytes) AS index,
             pg_size_pretty(toast_bytes) AS toast,
             pg_size_pretty(table_bytes) AS table
FROM ( SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
              FROM (SELECT c.oid, nspname AS table_schema,
                               relname AS table_name,
                               c.reltuples AS row_estimate,
                               pg_total_relation_size(c.oid) AS total_bytes,
                               pg_indexes_size(c.oid) AS index_bytes,
                               pg_total_relation_size(reltoastrelid) AS toast_bytes
                      FROM pg_class c
                      LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                      WHERE relkind = 'r'
                    ) a
           ) a
WHERE table_name LIKE '%table_to_delete%';

-- e) Recreate ‘table_to_delete’ Table time- 14 sec 121msec
DROP TABLE table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

-- 4️ Issue the TRUNCATE Operation
-- a) Note how much time it takes to perform this TRUNCATE statement time 96 msec
TRUNCATE table_to_delete;

-- b) Compare with previous results and make conclusion.
-- comparing with delete 11sec 56msec and 96msec 
-- compairing with vacuum 5 sec and 96msec

-- c) Check space consumption of the table once again
SELECT *, pg_size_pretty(total_bytes) AS total,
             pg_size_pretty(index_bytes) AS index,
             pg_size_pretty(toast_bytes) AS toast,
             pg_size_pretty(table_bytes) AS table
FROM ( SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
              FROM (SELECT c.oid, nspname AS table_schema,
                               relname AS table_name,
                               c.reltuples AS row_estimate,
                               pg_total_relation_size(c.oid) AS total_bytes,
                               pg_indexes_size(c.oid) AS index_bytes,
                               pg_total_relation_size(reltoastrelid) AS toast_bytes
                      FROM pg_class c
                      LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                      WHERE relkind = 'r'
                    ) a
           ) a
WHERE table_name LIKE '%table_to_delete%';
