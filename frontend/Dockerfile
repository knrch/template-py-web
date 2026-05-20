# syntax=docker/dockerfile:1.7
# Resolve real digests at bootstrap (mirror into docker-compose.yml + scripts/audit-all.sh):
#   docker pull node:24-alpine
#   docker inspect --format='{{index .RepoDigests 0}}' node:24-alpine
#   docker pull nginx:alpine
#   docker inspect --format='{{index .RepoDigests 0}}' nginx:alpine

FROM node:24-alpine@sha256:PIN_ME_AT_BOOTSTRAP AS builder
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM nginx:alpine@sha256:PIN_ME_AT_BOOTSTRAP
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080
