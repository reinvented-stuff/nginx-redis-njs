FROM alpine:3.16 as builder

ARG NGINX_VERSION=1.22.0
ARG NGINX_REDIS_VERSION=0.3.9
ARG NGINX_REDIS2_VERSION=0.15
ARG NGINX_NJS_VERSION=0.7.3

ENV NGINX_DOWNLOAD_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
ENV NGINX_REDIS_DOWNLOAD_URL="https://people.freebsd.org/~osa/ngx_http_redis-${NGINX_REDIS_VERSION}.tar.gz"
ENV NGINX_REDIS2_DOWNLOAD_URL="https://github.com/openresty/redis2-nginx-module/archive/refs/tags/v${NGINX_REDIS2_VERSION}.tar.gz"
ENV NGINX_NJS_DOWNLOAD_URL="https://hg.nginx.org/njs/archive/${NGINX_NJS_VERSION}.tar.gz"

RUN apk --update add openssl-dev pcre-dev zlib-dev wget build-base gd-dev geoip-dev perl-dev
RUN mkdir -pv /src

WORKDIR /src

RUN wget -qO- "${NGINX_DOWNLOAD_URL}" | tar -zxvf -
RUN wget -qO- "${NGINX_REDIS_DOWNLOAD_URL}" | tar -zxvf -
RUN wget -qO- "${NGINX_REDIS2_DOWNLOAD_URL}" | tar -zxvf -
RUN wget -qO- "${NGINX_NJS_DOWNLOAD_URL}" | tar -zxvf -

WORKDIR "/src/nginx-${NGINX_VERSION}"

RUN ./configure \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_geoip_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \

  --with-mail \
  --with-mail_ssl_module \

  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_geoip_module \
  --with-stream_ssl_preread_module \

  --prefix=/usr/share/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --sbin-path=/usr/sbin/nginx \
  --add-module="../ngx_http_redis-${NGINX_REDIS_VERSION}" \
  --add-module="../redis2-nginx-module-${NGINX_REDIS2_VERSION}" \
  --add-module="../njs-${NGINX_NJS_VERSION}/nginx"

RUN make && make install


FROM alpine:3.16

LABEL org.opencontainers.image.authors="Pavel Kim <hello@pavelkim.com>"
LABEL org.opencontainers.image.description="Nginx with Redis, Redis2 and njs"

ARG NGINX_EXPOSE=80 443

RUN apk add pcre-dev geoip

WORKDIR /

COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/share/nginx/html /usr/share/nginx/html
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

VOLUME ["/var/log/nginx", "/etc/nginx", "/usr/share/nginx"]

WORKDIR /etc/nginx

EXPOSE ${NGINX_EXPOSE}

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
