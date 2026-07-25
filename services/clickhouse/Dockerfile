# Pin the same ClickHouse release as Swetrix/selfhosting and bake in the
# RAM/log tuning configs from that repo.
FROM clickhouse/clickhouse-server:25.8-alpine

COPY config/reduce-logs.xml /etc/clickhouse-server/config.d/reduce-logs.xml
COPY config/preserve-ram-config.xml /etc/clickhouse-server/config.d/preserve-ram-config.xml
COPY config/disable-user-logging.xml /etc/clickhouse-server/users.d/disable-user-logging.xml
COPY config/preserve-ram-user.xml /etc/clickhouse-server/users.d/preserve-ram-user.xml
