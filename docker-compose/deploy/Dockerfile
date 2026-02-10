# Optimized Dockerfile for Docker Compose deployment
# This is a simplified version optimized for multi-service deployments
# Uses Node.js 22 for consistency with the rest of the project

# Build arguments
ARG NODEJS_VERSION=22
ARG USE_CN_MIRROR=false

# Base image with dependencies
FROM node:${NODEJS_VERSION}-slim AS base

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Builder stage
FROM base AS builder

WORKDIR /app

# Copy package files
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY .npmrc* ./

# Install pnpm and dependencies
RUN npm install -g corepack@latest && \
    corepack enable && \
    corepack use $(node -p "require('./package.json').packageManager || 'pnpm@latest'") && \
    pnpm install --frozen-lockfile=false

# Copy source code
COPY . .

# Build arguments
ARG NODE_ENV=production
ARG CI=true
ARG NEXT_TELEMETRY_DISABLED=1
ARG SKIP_TYPE_CHECK=false

ENV NODE_ENV=${NODE_ENV} \
    CI=${CI} \
    NEXT_TELEMETRY_DISABLED=${NEXT_TELEMETRY_DISABLED} \
    NODE_OPTIONS="--max-old-space-size=8192"

# Build the application
RUN pnpm run build:docker

# Production stage
FROM node:${NODEJS_VERSION}-slim AS production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN groupadd -r nextjs && useradd -r -g nextjs nextjs

# Copy built application
COPY --from=builder --chown=nextjs:nextjs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nextjs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nextjs /app/public ./public
COPY --from=builder --chown=nextjs:nextjs /app/packages/database/migrations ./migrations
COPY --from=builder --chown=nextjs:nextjs /app/scripts/serverLauncher/startServer.js ./startServer.js
COPY --from=builder --chown=nextjs:nextjs /app/scripts/_shared ./scripts/_shared

# Set environment
ENV NODE_ENV=production \
    PORT=3210 \
    HOSTNAME=0.0.0.0 \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca"

# Switch to non-root user
USER nextjs

EXPOSE 3210

ENTRYPOINT ["node", "startServer.js"]
