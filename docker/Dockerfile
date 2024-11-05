# Dockerfile for Node.js Application
FROM node:22

WORKDIR /usr/src/app

COPY ./src/package*.json ./

RUN npm install

COPY ./src ./

EXPOSE 5000

CMD ["node", "src/app.js"]
