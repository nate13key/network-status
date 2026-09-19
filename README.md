# network-status

A small web dashboard that shows how reliable my network has been recently.

A worker pings 8.8.8.8 and runs a DNS lookup with `dig` once per second, logging every result to PostgreSQL. A FastAPI service turns that data into summaries, and a static page served by nginx displays them. The page shows fresh data on load; refresh it to get the latest (no live updates).

The project is in early development.
