FROM experimentalplatform/ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y -q --no-install-recommends openjdk-8-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN TMPFILE=$(mktemp); curl -q --fail https://download.forgerock.org/downloads/opendj/nightly/20160713_2328/opendj-4.0.0-20160713.zip > $TMPFILE && unzip $TMPFILE && rm $TMPFILE

RUN echo 'export PATH="$PATH:/opt/opendj/bin"' >> /etc/bash.bashrc

COPY opendj-install.properties /opt/opendj-install.properties
COPY initial.ldif /initial.ldif
COPY entrypoint.sh /entrypoint.sh

WORKDIR /opt/opendj

CMD /entrypoint.sh

EXPOSE 1389
