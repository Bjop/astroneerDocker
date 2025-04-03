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

# Set environment variables
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