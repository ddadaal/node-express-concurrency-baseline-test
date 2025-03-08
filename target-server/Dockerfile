FROM node:22-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files and install dependencies
COPY package.json ./
RUN pnpm install

# Copy source code and build
COPY tsconfig.json ./
COPY src ./src
RUN pnpm build

EXPOSE 5001

CMD ["node", "dist/index.js"]
