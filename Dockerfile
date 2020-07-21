ARG NODEJS_VERSION
FROM mhart/alpine-node:${NODEJS_VERSION} as build

RUN apk update && apk add --no-cache python3
RUN apk update && apk add --no-cache make
RUN apk update && apk add --no-cache g++
RUN apk update && apk add --no-cache libcap

# RUN setcap 'cap_net_admin,cap_net_raw,cap_net_bind_service=+ep' `which node`
RUN setcap 'cap_net_admin=+eip cap_net_bind_service=+eip cap_net_raw=+eip' $(eval readlink -f `which node`)

WORKDIR /app

COPY package.json ./
RUN npm install
COPY . ./
RUN ./node_modules/.bin/grunt
RUN ./node_modules/.bin/grunt test
RUN ./node_modules/.bin/grunt build

FROM mhart/alpine-node:${NODEJS_VERSION} as deploy

RUN apk update && apk add --no-cache python3
RUN apk update && apk add --no-cache make
RUN apk update && apk add --no-cache g++
RUN apk update && apk add --no-cache libcap

# RUN setcap 'cap_net_admin,cap_net_raw,cap_net_bind_service=+ep' `which node`
RUN setcap 'cap_net_admin=+eip cap_net_bind_service=+eip cap_net_raw=+eip' $(eval readlink -f `which node`)

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

WORKDIR /app
RUN addgroup nonroot && \
    adduser -D nonroot -G nonroot && \
    chown nonroot:nonroot /app

USER nonroot

RUN mkdir -p /home/nonroot/.npm
VOLUME /home/nonroot/.npm
COPY package.json ./
RUN npm install --production
COPY --chown=nonroot:nonroot --from=build /app/built /app/
