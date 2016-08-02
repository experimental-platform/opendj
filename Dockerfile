FROM quay.io/experimentalplatform/ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y -q --no-install-recommends slapd ldap-utils ruby2.3 && \
    gem install --no-rdoc --no-ri bundler && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ldif-builder /opt/ldif-builder
RUN cd /opt/ldif-builder && bundle && bundle exec rspec spec.rb

COPY ldif-builder/example-users.json /etc/ldap/users.json
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dumb-init", "/entrypoint.sh"]