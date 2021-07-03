# Container image that runs your code
FROM alpine:3.13

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

RUN apk update && apk add --upgrade --no-cache ca-certificates curl jq && \
  curl -s https://downloads.accurics.com/cli/1.0.19/accurics_linux -o /usr/bin/accurics && \
  chmod 755 /entrypoint.sh /usr/bin/accurics

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

