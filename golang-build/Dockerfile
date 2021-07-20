FROM docker.io/goreng/golang-cross-builder:v1.16.2

LABEL "name"="Go Builder"
LABEL "maintainer"="Sean Russell <ser@ser1.net>"
LABEL "version"="0.0.1"

LABEL "com.github.actions.name"="Go Builder"
LABEL "com.github.actions.description"="Cross-complile Go programs"
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="#E0EBF5"

RUN \
  apt-get update && \
  apt-get install -y ca-certificates openssl zip upx && \
  update-ca-certificates && \
  rm -rf /var/lib/apt

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
