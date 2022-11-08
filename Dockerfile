FROM alpine as builder
RUN apk add curl bash jq uuidgen

COPY test* /usr/local/bin/
COPY utils/ /usr/local/bin/utils/
COPY bogus-mtls/ /usr/local/bin/bogus-mtls/

WORKDIR /usr/local/bin
CMD ["test-xks-proxy", "-h"]
