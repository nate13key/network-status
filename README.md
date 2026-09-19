# network-status

A small web dashboard that shows how reliable my network has been recently.

A worker pings 8.8.8.8 and runs a DNS lookup with `dig` once per second, logging every result to PostgreSQL. A FastAPI service turns that data into summaries, and a static page served by nginx displays them. The page shows fresh data on load; refresh it to get the latest (no live updates).

The project is in early development.
## Usage
Here's a command to check the database
```docker
docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT * FROM checks ORDER BY id LIMIT 5;"'
```
