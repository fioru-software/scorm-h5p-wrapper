FROM node:12-alpine

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run copy-h5p-standalone
COPY edited-h5p-standalone/* src/template
EXPOSE 80
CMD [ "npm", "start" ]
