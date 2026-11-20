# nginx-redis-njs

Nginx compiled with Redis2, HttpRedis, and njs modules.

Versions:
* Nginx: 1.30.7 (stable)
* Redis2 module: 0.15
* HttpRedis module: 0.4.2
* njs module: 1.0.2


Also includes:
* compat
* threads
* pcre-jit
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
* http_v3_module
* mail
* mail_ssl_module
* stream
* stream_ssl_module
* stream_realip_module
* stream_geoip_module
* stream_ssl_preread_module

All modules are compiled in statically. Configs written for packaged nginx must drop their `load_module` lines.

# Official documentation

Nginx: https://nginx.org/en/docs/

njs: https://nginx.org/en/docs/njs/

Redis2: https://github.com/openresty/redis2-nginx-module

HttpRedis: https://github.com/osokin/ngx_http_redis

# Image defaults

* The built-in config listens on port 80 and serves `/usr/share/nginx/html`.
* `/var/log/nginx/access.log` and `error.log` point to stdout and stderr, so `docker logs` shows them. Mount `/var/log/nginx` to write log files instead.
* Worker processes run as `nginx` (uid/gid 101) unless the config sets `user`.
* The pid file is `/run/nginx.pid`; temporary files go to `/var/cache/nginx`.
* `docker stop` sends `SIGQUIT`, so nginx finishes in-flight requests before exiting.

# Redis modules

The image has two Redis modules. They can be used side by side.

**HttpRedis** (`redis_pass`) answers a `GET` with the stored value as the response body, or 404 if the key is missing. It is configured with variables:

```
location /x-auth {
    internal;
    set $redis_db   1;                                  # optional, default 0
    set $redis_auth secretpass;                         # optional, sends AUTH first
    set $redis_key  /x-auth-token/$http_x_auth_token;
    redis_pass      127.0.0.1:6379;
}
```

The module URL-escapes the key before the lookup, so a key containing spaces or `%` must be stored in its escaped form (for example `/file%20name`).

**Redis2** (`redis2_query`, `redis2_pass`) can send any Redis command, but returns the raw Redis protocol reply (for example `$5\r\nhello\r\n`). Parse it in njs if you need the value.

Mark Redis locations `internal` when only njs subrequests should reach them.

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
    ghcr.io/reinvented-stuff/nginx-redis-njs/nginx-redis-njs:2.3.0-1.30.7-0.15-1.0.2-0.4.2
```

Check that it works:
```
curl http://127.0.0.1:10080/
curl -k https://127.0.0.1:10443/
```

Both should answer `Hello`.
