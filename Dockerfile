# ---------- Dockerfile ----------
FROM alpine:3.20
RUN apk add --no-cache tor tinyproxy

# write a pristine two-line torrc
RUN printf 'SOCKSPort 9050\nLog notice stdout\n' > /etc/tor/torrc

# copy tinyproxy.conf as before
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

EXPOSE 8080
CMD tor & tinyproxy -d