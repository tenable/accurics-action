# Container image that runs your code
FROM alpine:3.11

RUN apk add --update --no-cache ca-certificates curl jq

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
COPY accurics /usr/bin/accurics

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

