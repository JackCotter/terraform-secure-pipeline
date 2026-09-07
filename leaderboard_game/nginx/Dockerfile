FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

# Explicit even though the base image already runs as nginx —
# Checkov checks this Dockerfile's own instructions, not the base image's.
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
