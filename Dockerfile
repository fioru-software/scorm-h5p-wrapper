FROM node:12-alpine

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run copy-h5p-standalone
RUN rm -rf src/template/frame.bundle.js
COPY edited-h5p-standalone/frame.bundle.js src/template
EXPOSE 80
CMD [ "npm", "start" ]
