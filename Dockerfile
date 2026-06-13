FROM node:20-alpine

WORKDIR /app

COPY container/nodejs/package*.json ./
COPY container/nodejs/ .

RUN apk add --no-cache bash curl && \
    npm install && \
    chmod +x start.sh

EXPOSE 3000/tcp

CMD ["node", "index.js"]
