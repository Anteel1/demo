
# syntax=docker/dockerfile:1.6
FROM node:20-alpine AS base
WORKDIR /repo
ENV CI=true

FROM base AS deps
RUN apk add --no-cache libc6-compat
COPY package*.json ./
RUN npm ci

FROM base AS builder
COPY --from=deps /repo/node_modules ./node_modules
COPY . .
ARG APP_NAME=resource-module
RUN npx nest build ${APP_NAME}

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ARG APP_NAME=resource-module
COPY --from=builder /repo/dist/apps/${APP_NAME} ./dist
COPY --from=builder /repo/package*.json ./
COPY --from=deps /repo/node_modules ./node_modules
RUN npm prune --omit=dev || true
EXPOSE 3000
CMD ["node", "dist/main.js"]
