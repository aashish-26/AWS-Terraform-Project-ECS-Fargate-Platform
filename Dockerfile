FROM node:18-alpine

WORKDIR /usr/src/app

# Copy simple HTTP server (no external dependencies)
COPY app/server.js .

ENV PORT=8080
EXPOSE 8080

CMD ["node", "server.js"]


