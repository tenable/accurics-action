# Container image that runs your code
FROM alpine:3.13

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

ARG TERRASCAN_VERSION=1.15.0
ARG CLI_VERSION=1.0.37
RUN apk update && apk add --upgrade --no-cache ca-certificates curl jq git && \
  curl -s https://downloads.accurics.com/cli/dev/${CLI_VERSION}/accurics_linux -o /usr/bin/accurics && \
  chmod 755 /entrypoint.sh /usr/bin/accurics
  
RUN curl --location https://github.com/accurics/terrascan/releases/download/v${TERRASCAN_VERSION}/terrascan_${TERRASCAN_VERSION}_Linux_x86_64.tar.gz -o terrascan.tar.gz && \
    tar xvfz terrascan.tar.gz && \
    rm -f terrascan.tar.gz && \
    mv terrascan /usr/bin/ && \
    terrascan version
    
    

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

