FROM node:20

WORKDIR /app

COPY package.json yarn.lock ./

RUN yarn global add @medusajs/medusa-cli@latest

RUN yarn install 

COPY . .

# or "start" for production
CMD ["yarn", "dev"] 