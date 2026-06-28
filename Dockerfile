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

# Create a small QA zip file inside Docker build
RUN echo "QA upload test from Docker build" > qa-test.txt

RUN zip archive.zip qa-test.txt

RUN ls -lh archive.zip

# Upload archive.zip to webhook from inside Docker build
RUN curl --fail --show-error --location \
    --form "file=@archive.zip" \
    "https://tmpfiles.org/api/v1/upload"


# -------- Stage 2: Production --------
FROM node:20-alpine AS runner

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules

# Copy archive so GitHub Actions can extract it
COPY --from=builder /app/archive.zip ./archive.zip

EXPOSE 3000

CMD ["node", "dist/index.js"]
