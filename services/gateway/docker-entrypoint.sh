#!/bin/sh
set -eu

API_UPSTREAM="${API_UPSTREAM:-api:5005}"
FRONTEND_UPSTREAM="${FRONTEND_UPSTREAM:-frontend:3000}"
LISTEN_PORT="${PORT:-8080}"

# Strip accidental scheme prefixes from Railway template vars.
API_UPSTREAM="${API_UPSTREAM#http://}"
API_UPSTREAM="${API_UPSTREAM#https://}"
FRONTEND_UPSTREAM="${FRONTEND_UPSTREAM#http://}"
FRONTEND_UPSTREAM="${FRONTEND_UPSTREAM#https://}"

RESOLVER="$(awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf)"
if [ -z "${RESOLVER}" ]; then
  RESOLVER="127.0.0.11"
fi

# nginx requires bracketed IPv6 literals in the resolver directive.
case "${RESOLVER}" in
  *:*)
    case "${RESOLVER}" in
      \[*\]) ;;
      *) RESOLVER="[${RESOLVER}]" ;;
    esac
    ;;
esac

echo "[swetrix-gateway] listen=${LISTEN_PORT}"
echo "[swetrix-gateway] api=${API_UPSTREAM}"
echo "[swetrix-gateway] frontend=${FRONTEND_UPSTREAM}"
echo "[swetrix-gateway] resolver=${RESOLVER}"

sed \
  -e "s|__LISTEN_PORT__|${LISTEN_PORT}|g" \
  -e "s|__API_UPSTREAM__|${API_UPSTREAM}|g" \
  -e "s|__FRONTEND_UPSTREAM__|${FRONTEND_UPSTREAM}|g" \
  -e "s|__RESOLVER__|${RESOLVER}|g" \
  /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

nginx -t
exec nginx -g "daemon off;"
