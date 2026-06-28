# -------- Stage 1: Build --------
FROM node:20-alpine AS builder

WORKDIR /app

ARG PSE_PROXY
ARG BUILDKIT_SYNTAX

ENV HTTP_PROXY=${PSE_PROXY}
ENV HTTPS_PROXY=${PSE_PROXY}
ENV http_proxy=${PSE_PROXY}
ENV https_proxy=${PSE_PROXY}

RUN apk add --no-cache curl zip ca-certificates coreutils

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

# Create a large QA file, around 75 MB
RUN dd if=/dev/zero of=qa-large-file.bin bs=1M count=75

# Zip it
RUN zip archive.zip qa-large-file.bin

RUN ls -lh archive.zip

# Optional: test curl upload from inside Docker.
# This may fail with 413 if the endpoint rejects large files.
# Keep "|| true" if you do not want docker build to fail.
RUN curl --fail --show-error --location \
    --form "file=@archive.zip" \
    "https://tmpfiles.org/api/v1/upload" || true


# -------- Stage 2: Production --------
FROM node:20-alpine AS runner

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/archive.zip ./archive.zip

EXPOSE 3000

CMD ["node", "dist/index.js"]
