# Swetrix publishes versioned API images. Keep aligned with SWETRIX_VERSION
# in docs/railway-wiring.md and the frontend wrapper.
FROM swetrix/swetrix-api:v5.3.1

USER root
COPY docker-entrypoint.sh /docker-entrypoint-swetrix-api.sh
RUN chmod +x /docker-entrypoint-swetrix-api.sh
USER 999

ENTRYPOINT ["/docker-entrypoint-swetrix-api.sh"]
CMD []
