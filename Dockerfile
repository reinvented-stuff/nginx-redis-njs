ARG ALPINE_VERSION=3.24

ARG NGINX_VERSION=1.30.7
ARG NGINX_SHA256=2565b5c837050e958f70fb0f73c48e2bca4542ad349fd356f46fb0c72610bc6e
ARG NGINX_REDIS2_VERSION=0.15
ARG NGINX_REDIS2_SHA256=d255571bcfb9939b78099df39cb4d42f174d789aec8c8e5e47b93942b0299438
ARG NGINX_HTTP_REDIS_VERSION=0.4.2
ARG NGINX_HTTP_REDIS_SHA256=36437bd550df2e0f388127dbbac7938beaba72a5aabc3380e9e6d632060a48cc
ARG NGINX_NJS_VERSION=1.0.2
ARG NGINX_NJS_SHA256=84a114499fa6878d3ec52b99c1cf2874a91eb0d915408f418a2b1279519f09ae


FROM alpine:${ALPINE_VERSION} AS builder

ARG NGINX_VERSION
ARG NGINX_SHA256
ARG NGINX_REDIS2_VERSION
ARG NGINX_REDIS2_SHA256
ARG NGINX_HTTP_REDIS_VERSION
ARG NGINX_HTTP_REDIS_SHA256
ARG NGINX_NJS_VERSION
ARG NGINX_NJS_SHA256

RUN apk add --no-cache \
      build-base \
      geoip-dev \
      libxml2-dev \
      libxslt-dev \
      openssl-dev \
      pcre2-dev \
      zlib-dev

WORKDIR /src

RUN set -eux; \
    wget -qO nginx.tar.gz      "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"; \
    wget -qO redis2.tar.gz     "https://github.com/openresty/redis2-nginx-module/archive/refs/tags/v${NGINX_REDIS2_VERSION}.tar.gz"; \
    wget -qO http_redis.tar.gz "https://github.com/osokin/ngx_http_redis/archive/refs/tags/${NGINX_HTTP_REDIS_VERSION}.tar.gz"; \
    wget -qO njs.tar.gz        "https://github.com/nginx/njs/archive/refs/tags/${NGINX_NJS_VERSION}.tar.gz"; \
    printf '%s  %s\n' \
      "${NGINX_SHA256}"            nginx.tar.gz \
      "${NGINX_REDIS2_SHA256}"     redis2.tar.gz \
      "${NGINX_HTTP_REDIS_SHA256}" http_redis.tar.gz \
      "${NGINX_NJS_SHA256}"        njs.tar.gz \
      | sha256sum -c -; \
    for f in nginx redis2 http_redis njs; do tar -vxzf "${f}.tar.gz"; done

WORKDIR /src/nginx-${NGINX_VERSION}

RUN ./configure \
      --prefix=/usr/share/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --pid-path=/run/nginx.pid \
      --lock-path=/run/nginx.lock \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --user=nginx \
      --group=nginx \
      --with-compat \
      --with-threads \
      --with-pcre-jit \
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
      --with-http_v3_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_ssl_module \
      --with-stream_realip_module \
      --with-stream_geoip_module \
      --with-stream_ssl_preread_module \
      --add-module="../redis2-nginx-module-${NGINX_REDIS2_VERSION}" \
      --add-module="../ngx_http_redis-${NGINX_HTTP_REDIS_VERSION}" \
      --add-module="../njs-${NGINX_NJS_VERSION}/nginx" \
 && make -j"$(nproc)" \
 && make install \
 && strip /usr/sbin/nginx


FROM alpine:${ALPINE_VERSION}

ARG NGINX_VERSION
ARG NGINX_REDIS2_VERSION
ARG NGINX_HTTP_REDIS_VERSION
ARG NGINX_NJS_VERSION
ARG BUILD_VERSION=dev
ARG VCS_REF=unknown

LABEL org.opencontainers.image.authors="Pavel Kim <hello@pavelkim.com>" \
      org.opencontainers.image.title="nginx-redis-njs" \
      org.opencontainers.image.description="Nginx ${NGINX_VERSION} with redis2 ${NGINX_REDIS2_VERSION}, HttpRedis ${NGINX_HTTP_REDIS_VERSION} and njs ${NGINX_NJS_VERSION}" \
      org.opencontainers.image.version="${BUILD_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/reinvented-stuff/nginx-redis-njs"

RUN apk add --no-cache \
      geoip \
      libcrypto3 \
      libssl3 \
      libxml2 \
      pcre2 \
      zlib \
 && addgroup -S -g 101 nginx \
 && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
 && mkdir -p /var/cache/nginx /var/log/nginx \
 && ln -sf /dev/stdout /var/log/nginx/stdout-access.log \
 && ln -sf /dev/stderr /var/log/nginx/stdout-error.log

COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/share/nginx/html /usr/share/nginx/html
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

WORKDIR /etc/nginx

EXPOSE 80 443 443/udp

STOPSIGNAL SIGQUIT

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
