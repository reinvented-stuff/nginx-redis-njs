# nginx-redis-njs

Nginx compiled with Redis and njs modules.

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


# Usage example

Create directories:
```
mkdir -pv /opt/nginx-redis-njs/etc/nginx
mkdir -pv /opt/nginx-redis-njs/var/log/nginx
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
    -v "/opt/nginx-redis-njs/var/log/nginx:/var/log/nginx" \
    ghcr.io/reinvented-stuff/nginx-redis-njs/nginx-redis-njs:1.0.3
```
