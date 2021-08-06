FROM alpine:latest

RUN apk --update --no-cache --no-progress add \
    openvpn \
    easy-rsa \
    && rm -rf /var/cache/apk/*

ADD entrypoint.sh /
CMD [ "/entrypoint.sh" ]