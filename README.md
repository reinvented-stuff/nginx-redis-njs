# nginx-redis-njs

Nginx compiled with Redis2, and njs modules.

Versions:
* Nginx: 1.31.9
* Redis2 module: 0.15
* njs module: 0.9.0


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

Redis2: https://github.com/openresty/redis2-nginx-module

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
  -out /opt/nginx-redis-njs/etc/pki/tls/certs/helloworld.crt \
  -sha256 \
  -days 9365
```

Provision nginx configuration and the njs example from this repository:
```
git clone https://github.com/reinvented-stuff/nginx-redis-njs.git
cd nginx-redis-njs
cp -Rv examples/nginx-redis-njs/etc/nginx/. /opt/nginx-redis-njs/etc/nginx/
cp -Rv examples/nginx-redis-njs/usr/share/nginx/. /opt/nginx-redis-njs/usr/share/nginx/
```

The example serves an njs handler (`usr/share/nginx/njs/helloworld.js`) on port 10080 (HTTP) and 10443 (HTTPS).

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
    ghcr.io/reinvented-stuff/nginx-redis-njs/nginx-redis-njs:2.3.0-1.31.9-0.15-0.9.0
```

Check that it works:
```
curl http://127.0.0.1:10080/
curl -k https://127.0.0.1:10443/
```

Both should answer `Hello`.
