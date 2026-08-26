FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip ca-certificates \
    libfontconfig1 libgl1 libglu1-mesa libxi6 libxcursor1 \
    libxinerama1 libxrandr2 libasound2 libpulse0 libdbus-1-3 libexpat1 \
    && rm -rf /var/lib/apt/lists/*

ARG GODOT_VERSION=4.7.1
RUN wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    -O /tmp/godot.zip \
    && unzip /tmp/godot.zip -d /usr/local/bin/ \
    && mv "/usr/local/bin/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

WORKDIR /app
COPY project.godot start_server.sh ./
RUN chmod +x start_server.sh
COPY scripts/ scripts/
COPY resources/ resources/ 2>/dev/null || true
COPY addons/ addons/ 2>/dev/null || true
COPY scenes/ scenes/ 2>/dev/null || true
COPY assets/audio/ assets/audio/ 2>/dev/null || true
COPY assets/ui/ assets/ui/ 2>/dev/null || true
COPY assets/branding/ assets/branding/ 2>/dev/null || true
COPY assets/shaders/ assets/shaders/ 2>/dev/null || true

ENV SERVER_PORT=7777
EXPOSE 7777

CMD ["/app/start_server.sh"]
