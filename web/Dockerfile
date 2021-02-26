FROM node:lts

LABEL maintainer="wanhuasong@ones.ai"

WORKDIR /web

COPY . .

ARG REACT_APP_BASE_URL

RUN npm config set registry https://registry.npm.taobao.org && \
npm install && \
npm run build && \
npm install -g serve

ENTRYPOINT [ "serve", "-s", "build" ]
CMD [ "-l", "3214" ]
