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

# Example with Redis (Docker Compose)

`examples/nginx-redis-njs/compose.yml` runs the image together with Redis. A small page at `/kv/` writes values through njs + redis2 and reads them back through either module, so you can compare the two.

```
cd examples/nginx-redis-njs
cp .env.example .env          # then set your own REDIS_PASSWORD
docker compose up -d --build
```

Open http://127.0.0.1:20080/kv/ (or https://127.0.0.1:20443/kv/ with the committed self-signed certificate). `/` says `Hello` and links to the test pages.

| Request | Module | What it does |
|---|---|---|
| `GET /kv/` | static | The page (plain HTML, no JavaScript) |
| `POST /api/kv` (form fields `key`, `value`) | njs + redis2 | Stores `demo:<key>` for one hour |
| `GET /api/r2?key=<key>` | njs + redis2 | The value, its TTL, and the raw Redis reply |
| `GET /api/hr?key=<key>` | HttpRedis | The value only, or 404 |

Where things are configured (paths relative to `examples/nginx-redis-njs/`):
* `compose.yml`: the Redis password, ACL and memory limit; the nginx container's ports and restrictions.
* `etc/nginx/nginx.conf`: `env REDIS_PASSWORD`, so njs can read the password.
* `etc/nginx/conf.d/10_helloworld.conf`: the Redis upstream and all key/value locations.
* `usr/share/nginx/njs/kv.js`: input checks, the cross-site check, parsing of redis2 replies.

What keeps it reasonably safe for a local example:
* Redis is on an internal-only network, and nginx listens on 127.0.0.1 only.
* The Redis user can only read and write `demo:*` keys (GET, SET, SELECT, PING, TTL). Anything else, such as `FLUSHALL` or `KEYS`, is refused.
* Keys are 1-64 characters (letters, digits, `.`, `_`, `-`), values at most 1 KB, and every value expires after an hour. Redis keeps nothing on disk and uses at most 32 MB.
* Writes are rate-limited (5 per second per client, bursts of 10) and must come from the same origin.
* Responses are plain text, the page loads no scripts, and the nginx container runs read-only with almost all Linux capabilities dropped.

There is no login: anyone who can reach the ports can read and write `demo:*` keys. Don't expose it beyond your machine as is.

`docker compose logs nginx` shows nginx's main error log. Requests and njs errors go to the per-site logs in the `logs` volume, for example `docker compose exec nginx tail /var/log/nginx/helloworld-error.log`.

When Redis restarts, its values are lost, and nginx picks it up again within about 10 seconds (it re-resolves the `redis` name every 10 s).

## Replacing the TLS certificate

The example ships a self-signed pair for convenience. To make your own:

```
cd examples/nginx-redis-njs
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -subj '/CN=helloworld' \
  -keyout etc/pki/tls/private/helloworld.key \
  -out etc/pki/tls/certs/helloworld.crt
docker compose restart nginx
```

Don't commit a private key you use anywhere else.

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

The example serves an njs handler (`usr/share/nginx/njs/helloworld.js`) on port 20080 (HTTP) and 20443 (HTTPS).

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
curl http://127.0.0.1:20080/
curl -k https://127.0.0.1:20443/
```

Both should return a page that says `Hello` and links to the test pages.

This setup has no Redis, so the example's key/value endpoints answer `502 redis unavailable`. Use the Docker Compose example above for those.

# TODO

* Generate the example's TLS certificate at startup instead of committing it.
