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
        wget\
        procps\
    && rm -rf /var/lib/apt/lists/*

# Create a non-root steam user
RUN groupadd -g ${GID} steam \
    && useradd -u ${UID} -g ${GID} -ms /bin/bash steam \
    && mkdir -p /home/steam/.steam \
    && mkdir -p /home/steam/.local/share/Steam \
    && chown -R steam:steam /home/steam

# Set environment variables
ENV HOME=/home/steam
ENV STEAMCMD_DIR=/usr/games
ENV PATH="$STEAMCMD_DIR:$PATH"

USER steam
WORKDIR /home/steam

# Install Astroneer Dedicated Server using SteamCMD (correct path)
RUN mkdir -p /home/steam/astroneer
RUN steamcmd +login anonymous \
    +force_install_dir /home/steam/astroneer \
    +app_update 728470 validate \
    +quit

USER root
RUN mkdir -p /usr/share/wine/mono /usr/share/wine/gecko && \
    chown -R root:root /usr/share/wine/mono /usr/share/wine/gecko

# Download wine-mono and wine-gecko packages
RUN wget -O /usr/share/wine/mono/wine-mono-5.0.0-x86.msi \
    http://dl.winehq.org/wine/wine-mono/5.0.0/wine-mono-5.0.0-x86.msi
RUN wget -O /usr/share/wine/gecko/wine-gecko-2.47.1-x86_64.msi \
    http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.msi
RUN wget -O /usr/share/wine/gecko/wine-gecko-2.47.1-x86.msi \
    http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.msi

# Expose the desired port (default)
ENV SERVER_PORT=8777
EXPOSE ${SERVER_PORT}

# Copy the entrypoint script and ensure it has execute permissions
COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh

WORKDIR /home/steam/astroneer

# Use the entrypoint script: it will update Engine.ini then execute the CMD
ENTRYPOINT ["/home/steam/entrypoint.sh"]

# Run the server (the command will be passed to the entrypoint)
CMD ["wine", "AstroServer.exe"]