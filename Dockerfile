# ----------  Dockerfile ----------
FROM alpine:3.20
RUN apk add --no-cache tor tinyproxy
COPY torrc      /etc/tor/torrc
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
EXPOSE 8080
CMD tor & tinyproxy -d