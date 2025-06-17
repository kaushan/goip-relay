# ---------- Dockerfile ----------
FROM alpine:3.20
RUN apk add --no-cache tor tinyproxy

# tinyproxy: client → Tor SOCKS
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

EXPOSE 8080

# ----- ONE process per container: use tini to keep PID 1 tidy
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini","--"]

# Start tor with flags, then tinyproxy
CMD tor --SocksPort 9050 --Log "notice stdout" & \
    tinyproxy -d