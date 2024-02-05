# nginx-redis-njs

Nginx compiled with Redis, Redis2 and njs modules.

Versions:
* Nginx: 1.24.0
* Redis module: 0.3.9
* Redis2 module: 0.15
* njs module: 0.8.2


Also includes:
* http_addition_module
* http_auth_request_module
* http_geoip_module
* http_gunzip_module
* http_gzip_static_module
* http_random_index_module
* http_realip_module
* http_secure_link_module
* http_slice_module
* http_ssl_module
* http_stub_status_module
* http_sub_module
* http_v2_module
* mail
* mail_ssl_module
* stream
* stream_ssl_module
* stream_realip_module
* stream_geoip_module
* stream_ssl_preread_module

# Official documentation

Nginx: https://nginx.org/en/docs/

njs: https://nginx.org/en/docs/njs/

Redis: https://www.nginx.com/resources/wiki/modules/redis/

Redis2: https://www.nginx.com/resources/wiki/modules/redis2/

# Usage example

Create directories:
```
mkdir -pv /opt/nginx-redis-njs/etc/nginx
mkdir -pv /opt/nginx-redis-njs/var/log/nginx
mkdir -pv /opt/nginx-redis-njs/usr/share/nginx
mkdir -pv /opt/nginx-redis-njs/etc/pki/tls/certs
mkdir -pv /opt/nginx-redis-njs/etc/pki/tls/private
```

Generate self-signed certificate:
```
openssl req -x509 \
  -newkey rsa:4096 \
  -subj '/CN=helloworld' \
  -nodes \
  -keyout /opt/nginx-redis-njs/etc/pki/tls/private/helloworld.key \
  -out /opt/nginx-redis-njs/etc/pki/tls/certs/helloworld.cert \
  -sha256 \
  -days 9365
```

Provision nginx configuration:
```
# tbd
```

Run container:
```
podman run \
    --name nginx-redis-njs \
    --rm \
    -t -i \
    --detach \
    --net="host" \
    --pid="host" \
    -v "/opt/nginx-redis-njs/etc/nginx:/etc/nginx" \
    -v "/opt/nginx-redis-njs/etc/pki/:/etc/pki" \
    -v "/opt/nginx-redis-njs/var/log/nginx:/var/log/nginx" \
    -v "/opt/nginx-redis-njs/usr/share/nginx:/usr/share/nginx" \
    ghcr.io/reinvented-stuff/nginx-redis-njs/nginx-redis-njs:1.0.3
```
