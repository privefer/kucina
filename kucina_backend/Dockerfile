# syntax=docker/dockerfile:1

# ---------------------------------------------------------
# Stage 1: Build & Dependencies
# ---------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies if needed for native modules
RUN apk add --no-cache python3 make g++

COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# ---------------------------------------------------------
# Stage 2: Production Runtime
# ---------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /app

# Add curl for container healthcheck
RUN apk add --no-cache curl

ENV NODE_ENV=production
ENV PORT=3000

# Create application directories
RUN mkdir -p /app/data && chown -R node:node /app

# Copy production node_modules from builder
COPY --from=builder --chown=node:node /app/node_modules ./node_modules

# Copy application source code
COPY --chown=node:node package*.json ./
COPY --chown=node:node src/ ./src/
COPY --chown=node:node public/ ./public/

# Switch to non-root user
USER node

# Expose API & Web Portal port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]
