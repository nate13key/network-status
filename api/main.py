from fastapi import FastAPI

app = FastAPI()

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/latest/dns")
def latest_dns(response: Response):
    response.headers["Cache-Control"] = "no-store"
    try:
        # No arguments: libpq reads PGHOST, PGUSER, PGPASSWORD, PGDATABASE
        # from the environment, the same way psql does in the worker.
        with psycopg.connect(row_factory=dict_row, connect_timeout=3) as conn:
            row = conn.execute(
                """
                SELECT ts, target, success, latency_ms, error
                FROM checks
                WHERE check_type = 'dns'
                ORDER BY ts DESC
                LIMIT 1
                """
            ).fetchone()
    except psycopg.OperationalError:
        raise HTTPException(status_code=503, detail="database unavailable")
    if row is None:
        raise HTTPException(status_code=404, detail="no dns checks yet")
    return row
