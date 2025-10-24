FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
ENV WINEPREFIX=/home/wine/.wine
ENV DISPLAY=:99.0

# Copy the package list early (while still root)
COPY packages.txt /tmp/packages.txt

# Install all dependencies as root
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    xargs -a /tmp/packages.txt apt-get install -y --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create wine user and give sudo rights
RUN useradd -m -s /bin/bash wine && \
    echo "wine:changeme" | chpasswd && \
    echo "wine ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/wine/scripts && \
    chown -R wine:wine /home/wine

# Copy your helper scripts
WORKDIR /home/wine/scripts
COPY setup_server.sh setup_wine.sh run.sh startup.sh select_scenario.sh configure_game.sh setup_mods.sh install_world.sh init_docker.sh setup_ports.sh SpaceEngineers-Dedicated.cfg ./
RUN chmod +x *.sh && chown -R wine:wine /home/wine/scripts

# --- Replace outdated Winetricks with the latest version ---
RUN rm -f /usr/bin/winetricks && \
    wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks && \
    echo "✅ Updated to latest Winetricks"

# Switch to non-root user for runtime
USER wine
WORKDIR /home/wine

# Run initial wine setup if needed
RUN if [ ! -d "$WINEPREFIX" ]; then xvfb-run --auto-servernum /home/wine/scripts/setup_wine.sh; fi

# --- Auto-run startup.sh for every login shell ---
RUN echo 'if [ -f /home/wine/scripts/startup.sh ]; then /home/wine/scripts/startup.sh; fi' >> /home/wine/.bashrc

# Expose game ports
EXPOSE 27016/udp 8080/tcp

# Use login shell so .bashrc executes on attach or exec
ENTRYPOINT ["/bin/bash", "-l"]
