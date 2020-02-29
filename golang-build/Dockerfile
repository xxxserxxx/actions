FROM dockercore/golang-cross

LABEL "name"="Go Builder"
LABEL "maintainer"="Sean Russell <ser@ser1.net>"
LABEL "version"="0.4.0"

LABEL "com.github.actions.name"="Go Builder"
LABEL "com.github.actions.description"="Cross-complile Go programs"
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="#E0EBF5"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
