# Build stage: Install dependencies and build everything
FROM oven/bun:1.2.20-alpine AS builder
RUN apk add --no-cache libc6-compat curl
WORKDIR /app

# Accept environment variables as build arguments
ARG NODE_ENV=production
ARG DATABASE_URL
ENV NODE_ENV=$NODE_ENV
ENV DATABASE_URL=$DATABASE_URL

# Install Turbo globally for efficient builds
RUN bun add turbo --global

# Copy workspace files
COPY package.json bun.lock turbo.json tsconfig.json ./
COPY client ./client
COPY server ./server
COPY shared ./shared
# Copy .env file if it exists
COPY .env* ./

# Install all dependencies and build
RUN bun install 
RUN bun run turbo build

# Copy static assets from client to server for single origin setup
RUN rm -rf server/static && cp -r client/dist server/static

# Verify build artifacts exist
RUN ls -la server/dist/ && \
    ls -la client/dist/ && \
    ls -la shared/dist/ && \
    ls -la server/static/

# Production stage: Minimal runtime image
FROM oven/bun:1.2.20-alpine AS runner
WORKDIR /app
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup --system --gid 1001 bunjs && \
    adduser --system --uid 1001 bunjs

# Copy ONLY the built artifacts (no source code, no node_modules)
COPY --from=builder --chown=bunjs:bunjs /app/server/dist ./server/dist
COPY --from=builder --chown=bunjs:bunjs /app/server/static ./server/static
COPY --from=builder --chown=bunjs:bunjs /app/shared/dist ./shared/dist

# Copy .env file for runtime environment variables
COPY --from=builder --chown=bunjs:bunjs /app/.env* ./

# NO dependency installation needed - everything is bundled in dist!
# Switch to non-root user
USER bunjs

ENV NODE_ENV=production
EXPOSE 3000
CMD ["bun", "run", "server/dist/index.js"]