#!/bin/bash
set -e
# Running docker compose down
docker compose -f docker-compose-network.yml -f docker-compose-redis.yml -f docker-compose-postgres.yml -f docker-compose.yml down -v
