FROM quay.io/experimentalplatform/ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y -q --no-install-recommends slapd ldap-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./config/* /etc/ldap/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dumb-init", "/entrypoint.sh"]