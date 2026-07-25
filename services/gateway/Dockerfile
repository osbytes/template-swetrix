FROM nginx:1.31.1-alpine

COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-gateway.sh
RUN chmod +x /docker-entrypoint-gateway.sh

# Disable the stock template renderer; we render once at boot with Railway hosts.
ENV NGINX_ENVSUBST_TEMPLATE_DIR=""

EXPOSE 8080
ENTRYPOINT ["/docker-entrypoint-gateway.sh"]
