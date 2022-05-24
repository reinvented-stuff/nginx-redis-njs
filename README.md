```
podman run \
    --name nginx-redis-njs \
    --rm \
    -t -i \
    --detach \
    --net="host" \
    --pid="host" \
    -v "/tmp/nginx/var/log/nginx:/var/log/nginx" \
    -v "/tmp/nginx/etc/nginx:/etc/nginx" \
    -v "/tmp/nginx/etc/nginx/modules:/etc/nginx/modules" \
    ghcr.io/reinvented-stuff/nginx-redis-njs/nginx-redis-njs:1.0.0dev
```

mkdir -pv /tmp/nginx/var/log/nginx /tmp/nginx/etc/nginx /tmp/nginx/etc/nginx/modules
