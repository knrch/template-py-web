# syntax=docker/dockerfile:1.7
# Resolve real digest at bootstrap:
#   docker pull caddy:2-alpine
#   docker inspect --format='{{index .RepoDigests 0}}' caddy:2-alpine

FROM caddy:2-alpine@sha256:PIN_ME_AT_BOOTSTRAP
COPY Caddyfile /etc/caddy/Caddyfile
EXPOSE 80
