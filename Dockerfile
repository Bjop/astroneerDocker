FROM steamcmd/steamcmd:ubuntu-22
LABEL authors="Bjop"

ARG GID=1000
ARG UID=1000

RUN set -x \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
    gosu \
    jq \
    tzdata \
    xdg-user-dirs \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g ${GID} steam \
 && useradd -u ${UID} -g ${GID} -ms /bin/bash steam \
 && mkdir -p /home/steam/.local/share/Steam/ \
 && cp -R /root/.local/share/Steam/steamcmd/ /home/steam/.local/share/Steam/steamcmd/ \
 && chown -R ${UID}:${GID} /home/steam/.local/ \
 && gosu nobody true

RUN mkdir -p /config \
 && chown steam:steam /config

WORKDIR /config
ARG VERSION="DEV"
ENV VERSION=$VERSION
LABEL version=$VERSION
STOPSIGNAL SIGINT
EXPOSE 8777

VOLUME ["/astroneer"]
CMD ["./AstroServer.exe"]
