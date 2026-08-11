# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
FROM fireflyiii/core:latest

# Installer bashio pour lire la config HA (/data/options.json)
RUN curl -sSLf -o /usr/bin/bashio \
    "https://github.com/hassio-addons/bashio/releases/latest/download/bashio" \
    && chmod +x /usr/bin/bashio

# Copier le script d'init + run
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Le port interne de Firefly III
EXPOSE 8080

# Labels obligatoires HA
ARG BUILD_VERSION
ARG BUILD_ARCH
LABEL \
    io.hass.name="Firefly III" \
    io.hass.description="Gestionnaire de budget personnel self-hosté" \
    io.hass.type="app" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="Firefly III HA Add-on" \
    org.opencontainers.image.description="Firefly III officiel, SQLite, sans dépendance externe" \
    org.opencontainers.image.source="https://github.com/Jefedi/firefly-iii-ha-addon" \
    org.opencontainers.image.licenses="MIT"

CMD ["/run.sh"]