# Dockerizing Astro (Static) - 이동수하우스

## Quick start
docker build -t dshouse-web:latest -f Dockerfile .
docker run -it --rm -p 8080:80 dshouse-web:latest
# http://localhost:8080

## docker compose
docker compose up --build -d
# http://localhost:8080

## Notes
- Multi-stage: Node 20 (build) → NGINX (serve)
- Health: /health (curl 기반)
- SPA fallback enabled
