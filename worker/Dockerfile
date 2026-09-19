FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      iputils-ping dnsutils postgresql-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --chmod=755 worker.sh .

CMD ["/app/worker.sh"]
