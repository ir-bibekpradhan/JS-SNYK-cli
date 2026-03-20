# -------- Stage 1: Build --------
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm install --legacy-peer-deps

# Copy source and build
COPY . .


# -------- Stage 2: Production --------
FROM node:20-alpine AS runner

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules

# If you have a build output (uncomment one depending on your app)
COPY --from=builder /app/dist ./dist
# COPY --from=builder /app/build ./build

# Expose port
EXPOSE 3000

# Start app (adjust if needed)
CMD ["node", "dist/index.js"]
