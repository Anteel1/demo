
# syntax=docker/dockerfile:1.6

############################
# Base
############################
FROM node:20-alpine AS base
WORKDIR /repo/monorepo
ENV CI=true

############################
# Deps (cài deps ở monorepo/)
############################
FROM base AS deps
RUN apk add --no-cache libc6-compat
# package.json & package-lock.json nằm trong monorepo/
COPY monorepo/package*.json ./
# bắt buộc có package-lock.json; nếu chưa có hãy commit nó
RUN npm ci

############################
# Build app cụ thể
############################
FROM base AS builder
# dùng node_modules đã cài ở stage deps
COPY --from=deps /repo/monorepo/node_modules ./node_modules
# copy toàn bộ mã nguồn trong thư mục monorepo (apps, libs, nest-cli.json, tsconfig*, ...)
COPY monorepo/. .
# APP_NAME = tên app trong monorepo/apps/<APP_NAME> (match với nest-cli.json)
ARG APP_NAME=note-module
RUN npx nest build ${APP_NAME}

############################
# Runtime gọn nhẹ (cài prod deps tại runtime)
############################
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ARG APP_NAME=note-module

# copy dist của app
COPY --from=builder /repo/monorepo/dist/apps/${APP_NAME} ./dist

# cài prod deps từ package*.json ở monorepo
COPY monorepo/package*.json ./
RUN npm ci --omit=dev

# (tuỳ chọn) Prisma:
# COPY monorepo/prisma ./prisma
# RUN npx prisma generate

EXPOSE 3000
CMD ["node", "dist/main.js"]
