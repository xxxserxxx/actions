FROM archlinux:latest

LABEL "name"="Arch Package Builder"
LABEL "maintainer"="Sean Russell <ser@ser1.net>"
LABEL "version"="0.0.1"

LABEL "com.github.actions.name"="Arch Package Builder"
LABEL "com.github.actions.description"="For updating, building, and testing AUR packages. Includes aurpublish."
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="#E0EBF5"

RUN pacman --noconfirm -Sy
RUN pacman --noconfirm -S aurpublish 
RUN pacman --noconfirm -S binutils

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
