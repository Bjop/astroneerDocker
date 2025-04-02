FROM steamcmd/steamcmd:ubuntu-22
LABEL authors="Bjop"

ARG GID=1000
ARG UID=1000

# Install dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        gosu \
        jq \
        tzdata \
        xdg-user-dirs \
        winbind \
        xvfb \
        wine64 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root steam user
RUN groupadd -g ${GID} steam \
    && useradd -u ${UID} -g ${GID} -ms /bin/bash steam \
    && mkdir -p /home/steam/.steam \
    && mkdir -p /home/steam/.local/share/Steam \
    && chown -R steam:steam /home/steam

# Set Steam environment variables to avoid /root/ errors
ENV HOME=/home/steam
ENV STEAMCMD_DIR=/usr/games
ENV PATH="$STEAMCMD_DIR:$PATH"

USER steam
WORKDIR /home/steam

# Install Astroneer Dedicated Server using SteamCMD (correct path)
RUN steamcmd +login anonymous \
    +force_install_dir /home/steam/astroneer \
    +app_update 728470 validate \
    +quit

# Expose server ports
EXPOSE 8777 15000/udp 15777/udp

VOLUME ["/home/steam/astroneer"]

WORKDIR /home/steam/astroneer

# Run the server
CMD ["wine", "AstroServer.exe"]
