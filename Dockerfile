# Container image that runs your code
FROM alpine:3.12

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

RUN apk update && apk add --upgrade --no-cache ca-certificates curl jq && \
  curl -s https://downloads.accurics.com/cli/github-action/accurics -o /usr/bin/accurics && \
  chmod 755 /entrypoint.sh /usr/bin/accurics

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

