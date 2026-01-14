FROM --platform=$TARGETOS/$TARGETARCH ghcr.io/parkervcp/yolks:java_25

LABEL author="NATroutter" maintainer="contact@natroutter.fi"
LABEL org.opencontainers.image.source="https://github.com/NATroutter/egg-hytale"
LABEL org.opencontainers.image.description="Container para executar servidores do jogo Hytale"
LABEL org.opencontainers.image.licenses=MIT

# Trabalhar como root para o setup
USER root

# Copia o entrypoint do Pterodactyl
COPY --from=ghcr.io/parkervcp/yolks:java_25 --chmod=755 /entrypoint.sh /entrypoint.sh

# Instala dependências
RUN apt update -y && apt install -y unzip jq curl && rm -rf /var/lib/apt/lists/*

# Copia o entry.sh como root (para o usuário do container não conseguir modificá-lo)
COPY --chmod=755 ./entry.sh /entry.sh
RUN sed -i 's/\r$//' /entry.sh

# Copia o start.sh para /usr/local/bin (local protegido; não será sobrescrito por mounts de volume)
COPY --chmod=755 ./start.sh /usr/local/bin/start.sh
RUN sed -i 's/\r$//' /usr/local/bin/start.sh

# Troca para o usuário do container APENAS em runtime
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Inicia o container
CMD ["/bin/bash", "/entry.sh"]