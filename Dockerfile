FROM ubuntu:25.04
LABEL authors="Bjop"

ARG GID=1500
ARG UID=1500

# Install dependencies
RUN set -x \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gosu \
        jq \
        tzdata \
        xdg-user-dirs \
        winbind \
        xvfb \
        wine64 \
        wine32 \
        wine \
        wget\
        procps\
        unzip \
    && mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root steam user
RUN getent group steam || groupadd -g ${GID} steam \
    && useradd -u ${UID} -g ${GID} -ms /bin/bash steam \
    && mkdir -p /home/steam/.steam \
    && mkdir -p /home/steam/.local/share/Steam \
    && chown -R steam:steam /home/steam

# Set environment variables
ENV HOME=/home/steam
ENV STEAMCMD_DIR=/usr/games
ENV PATH="$STEAMCMD_DIR:$PATH"

USER root
RUN mkdir -p /usr/share/wine/mono /usr/share/wine/gecko && \
    chown -R root:root /usr/share/wine/mono /usr/share/wine/gecko

RUN mkdir -p /config/gamefiles && chown -R steam:steam /config


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

USER steam
WORKDIR /home/steam

# Install Astroneer Dedicated Server using SteamCMD (correct path)
RUN mkdir -p /config/gamefiles
#RUN steamcmd +login anonymous \
#             +force_install_dir /config/gamefiles \
#             +app_update 728470 validate \
#             +quit
ENV WINE64_DIR="/usr/local/bin/wine64"

RUN if [[ ":$PATH:" != *":${WINE64_DIR}:"* ]]; then \
        export PATH="${WINE64_DIR}:$PATH"; \
    fi

ENV WINE32_DIR="/usr/local/bin/wine32"

RUN if [[ ":$PATH:" != *":${WINE32_DIR}:"* ]]; then \
        export PATH="${WINE32_DIR}:$PATH"; \
    fi

RUN wget -O steamcmd.zip "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" && \
    unzip steamcmd.zip -d steamcmd_windows && \
    rm steamcmd.zip

# Run the Windows dedicated server install using Wine
# Note: Adjust the path if needed
RUN wineboot --init
RUN wine Z:\home\steam\steamcmd_windows\steamcmd.exe +login anonymous +force_install_dir Z:\config\gamefiles +app_update 728470 validate +quit



WORKDIR /config/gamefiles

# Use the entrypoint script: it will update Engine.ini then execute the CMD
ENTRYPOINT ["/home/steam/entrypoint.sh"]

# Run the server (the command will be passed to the entrypoint)
CMD ["wine", "AstroServer.exe"]