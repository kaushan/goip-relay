FROM alpine:3.20
RUN apk add --no-cache tor tinyproxy

# remove any torrc left from previous layers or base image
RUN rm -f /etc/tor/torrc

COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

EXPOSE 8080
CMD tor -f /dev/null \
        --SocksPort 9050 \
        --Log "notice stdout" \
        --GeoIPFile "" \
        --GeoIPv6File "" \
    & tinyproxy -d