FROM nginx:1.27-alpine

# checkov:skip=CKV_DOCKER_3: official nginx image already drops privileges
# internally — master process starts as root (required to bind port 80 and
# write /run/nginx.pid), then spawns worker processes as the "nginx" user
# per the "user nginx;" directive in the image's default nginx.conf. Adding
# a static USER line here breaks that startup (PID file permission errors).
# Verified at runtime with `docker exec <container> ps aux` -> worker
# processes run as nginx, only the master process (pid 1) is root.

RUN apk upgrade --no-cache

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY proxy-params.conf /etc/nginx/proxy_params.conf
COPY nginx-selfsigned.crt /etc/nginx/ssl/nginx-selfsigned.crt
COPY nginx-selfsigned.key /etc/nginx/ssl/nginx-selfsigned.key

EXPOSE 80 443

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
