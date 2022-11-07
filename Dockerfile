FROM alpine as builder
RUN apk add curl bash jq uuidgen

COPY test* /usr/local/bin/
COPY utils/ /usr/local/bin/utils/

WORKDIR /usr/local/bin
CMD ["test-xks-proxy", "-h"]
