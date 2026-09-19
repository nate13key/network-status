CREATE TABLE checks (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ts          timestamptz NOT NULL,
    check_type  text        NOT NULL,  -- 'ping' or 'dns'
    target      text        NOT NULL,  -- '8.8.8.8', gateway IP, etc.
    success     boolean     NOT NULL,
    latency_ms  real,                  -- NULL when the check failed
    error       text
);

CREATE INDEX checks_ts_idx ON checks (ts);
