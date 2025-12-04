# Web App Dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source files
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 80

# Set environment variables
ENV PORT=80
ENV NODE_ENV=production

# Start the application
CMD ["npm", "start"]
