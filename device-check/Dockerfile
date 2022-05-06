FROM balenalib/amd64-debian-node:12.22-bullseye-build as builder

WORKDIR /usr/src/app

COPY . ./
RUN JOBS=MAX npm install --production --unsafe-perm && npm --force cache clean && rm -rf /tmp/*

FROM balenalib/amd64-debian-node:12.22-bullseye-run

ENV BALENA_CLI_VERSION 13.4.1
WORKDIR /usr/src/app

RUN install_packages apt-transport-https curl unzip gnupg2 ssh
RUN  curl -sSL https://github.com/balena-io/balena-cli/releases/download/v$BALENA_CLI_VERSION/balena-cli-v$BALENA_CLI_VERSION-linux-x64-standalone.zip > balena-cli.zip && \
    unzip balena-cli.zip && mv balena-cli/* /usr/bin && rm -rf balena-cli.zip balena-cli

COPY --from=builder /usr/src/app/node_modules node_modules
COPY mdns-resolve.js mdns-resolve
COPY entry.sh /usr/src/app/entry.sh
RUN chmod u+x /usr/src/app/entry.sh

ENTRYPOINT [ "/usr/src/app/entry.sh" ]
