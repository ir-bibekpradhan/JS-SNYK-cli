# Base image
FROM node:20-alpine

# App directory
WORKDIR /app

# Copy dependency files first
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy project files
COPY . .

# Expose port (change if your app uses another)
EXPOSE 3000

# Start command
CMD ["npm", "start"]
