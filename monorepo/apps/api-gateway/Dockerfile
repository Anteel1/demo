
# syntax=docker/dockerfile:1.6

############################
# Base
############################
FROM node:20-alpine AS base
WORKDIR /repo/monorepo
ENV CI=true

############################
# Deps (cài deps ở root)
############################
FROM base AS deps
# Một số native deps cần libc6-compat trên Alpine
RUN apk add --no-cache libc6-compat
# Copy file khai báo deps ở root
COPY monorepo/package*.json ./
# (nếu có lockfile khác, ví dụ pnpm-lock.yaml, hãy copy tương ứng)
RUN npm ci

############################
# Build app cụ thể trong monorepo
############################
FROM base AS builder
COPY --from=deps /repo/node_modules ./node_modules
# Copy toàn bộ mã nguồn (apps, libs, nest-cli.json, tsconfig*, ...)
COPY . .
# APP_NAME = tên app trong thư mục apps/ và trong nest-cli.json
ARG APP_NAME=api-gateway
RUN npx nest build ${APP_NAME}

############################
# Runtime gọn nhẹ
############################
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Cần lại APP_NAME ở stage này
ARG APP_NAME=api-gateway

# Copy dist đúng app, và node_modules đã cài

COPY --from=builder /repo/monorepo/dist/apps/${APP_NAME} ./dist
COPY --from=builder /repo/monorepo/package*.json ./
COPY --from=deps    /repo/monorepo/node_modules ./node_modules


# Loại bỏ dev deps (không bắt buộc, nhưng nên)
RUN npm prune --omit=dev || true

# (tuỳ chọn) Prisma:
# COPY prisma ./prisma
# RUN npx prisma generate

EXPOSE 3000
CMD ["node", "dist/main.js"]
