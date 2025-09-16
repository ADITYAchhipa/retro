# Multi-stage Dockerfile for Rentally Express backend

# Development image with nodemon
FROM node:18-alpine AS dev
WORKDIR /app
ENV NODE_ENV=development

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm install

# Copy source
COPY . .

EXPOSE 5000
CMD ["npm", "run", "dev"]

# Production image
FROM node:18-alpine AS prod
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
# Prefer clean install; fall back to install if lockfile changes
RUN npm ci --omit=dev || npm install --omit=dev

COPY . .

EXPOSE 5000
CMD ["npm", "start"]
