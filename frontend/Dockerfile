# syntax=docker/dockerfile:1.7
FROM cgr.dev/chainguard/node:latest-dev AS builder
WORKDIR /app
USER root
RUN npm install -g pnpm@9.15.0
USER node
COPY --chown=node:node package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY --chown=node:node . .
RUN pnpm build

FROM cgr.dev/chainguard/nginx:latest
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080
