FROM node:19.4.0-alpine as ui-builder

ENV NODE_OPTIONS --openssl-legacy-provider

RUN mkdir /app

WORKDIR /app

# ENV PATH /usr/src/app/node_modules/.bin:$PATH

RUN wget --quiet https://github.com/freqtrade/frequi/archive/refs/tags/0.6.3.tar.gz -O /tmp/ui.tar.gz \
    && tar xf /tmp/ui.tar.gz -C /app --strip 1 \
    && rm /tmp/ui.tar.gz

RUN apk add --update --no-cache python3 g++ make \
    && yarn \
    && apk del python3 g++ make

RUN yarn build

FROM nginx:1.21.4-alpine
COPY  --from=ui-builder /app/dist /etc/nginx/html
COPY  --from=ui-builder /app/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx"]
