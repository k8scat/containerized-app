FROM openresty/openresty:1.19.3.1-centos

LABEL maintainer="K8sCat <k8scat@gmail.com>"
LABEL version="1.0.0"

COPY gateway.conf /etc/nginx/conf.d/gateway.conf
COPY gateway.lua /usr/local/openresty/nginx/conf/gateway.lua
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Install lua-resty-http
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
