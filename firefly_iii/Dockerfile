# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
# On part de l'image officielle Firefly III qui contient déjà PHP 8.2 + nginx + tout le nécessaire
FROM fireflyiii/core:latest

# s6-overlay pour la compatibilité Home Assistant (cont-init.d, services)
ARG S6_OVERLAY_VERSION=3.2.0.2
ARG TARGETARCH

RUN case "${TARGETARCH}" in \
        amd64)  s6_arch="x86_64" ;; \
        arm64)  s6_arch="aarch64" ;; \
        *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -sSLf -o /tmp/s6.tar.gz \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.gz" \
    && tar xzf /tmp/s6.tar.gz -C / \
    && curl -sSLf -o /tmp/s6-bin.tar.gz \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${s6_arch}.tar.gz" \
    && tar xzf /tmp/s6-bin.tar.gz -C / \
    && rm -f /tmp/s6.tar.gz /tmp/s6-bin.tar.gz

# Installer bashio pour lire la config HA (/data/options.json)
RUN curl -sSLf -o /usr/bin/bashio \
        "https://github.com/hassio-addons/bashio/releases/latest/download/bashio" \
    && chmod +x /usr/bin/bashio

# Copier le rootfs (scripts d'init + configs nginx)
COPY rootfs /

# Rendre les scripts exécutables
RUN chmod +x /etc/cont-init.d/*.sh /etc/services.d/*/run 2>/dev/null || true

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

# Entrypoint s6-overlay
ENTRYPOINT ["/init"]