#FROM node:lts-alpine3.18
FROM node:14.19.2-slim

WORKDIR /app

COPY package.json package.json

RUN npm install

COPY . .

EXPOSE 3000

RUN npm run build

CMD [ "serve", "-s", "build" ]