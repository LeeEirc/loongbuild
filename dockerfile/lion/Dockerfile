FROM ghcr.io/loong64/guacamole/guacd:1.5.5-trixie AS stage-1
FROM ghcr.io/loong64/debian:trixie-slim AS stage-2
ARG TARGETARCH

ARG DEPENDENCIES="                    \
        ca-certificates               \
        wget"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -e \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES}

WORKDIR /opt

ARG CHECK_VERSION=v1.0.4
RUN set -e \
    && wget --quiet https://github.com/jumpserver-dev/healthcheck/releases/download/${CHECK_VERSION}/check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xf check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz -C /usr/local/bin/ check \
    && chown root:root /usr/local/bin/check \
    && chmod 755 /usr/local/bin/check \
    && rm -f /opt/*.tar.gz

ARG WISP_VERSION=v0.2.7
RUN set -e \
    && wget --quiet https://github.com/jumpserver-dev/wisp/releases/download/${WISP_VERSION}/wisp-${WISP_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xf wisp-${WISP_VERSION}-linux-${TARGETARCH}.tar.gz -C /usr/local/bin/ wisp \
    && chown root:root /usr/local/bin/wisp \
    && chmod 755 /usr/local/bin/wisp \
    && rm -f /opt/*.tar.gz

ARG VERSION

RUN --mount=type=bind,source=dist,target=/dist \
    set -e \
    && mkdir -p /opt/lion \
    && tar -xf /dist/lion-${VERSION}-linux-${TARGETARCH}.tar.gz -C /opt/lion --strip-components=1 \
    && chmod 755 /opt/lion/*.sh \
    && chown -R root:root /opt/lion \
    && rm -f /opt/*.tar.gz

FROM ghcr.io/loong64/debian:trixie-slim
ENV LANG=en_US.UTF-8

ARG DEPENDENCIES="                    \
        ca-certificates               \
        supervisor"

ARG PREFIX_DIR=/opt/guacamole
ENV LD_LIBRARY_PATH=${PREFIX_DIR}/lib

COPY --from=stage-1 ${PREFIX_DIR} ${PREFIX_DIR}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -e \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends ${DEPENDENCIES} \
    && apt-get install -y --no-install-recommends $(cat "${PREFIX_DIR}"/DEPENDENCIES)

COPY --from=stage-2 /usr/local/bin /usr/local/bin
COPY --from=stage-2 /opt/lion /opt/lion
COPY --from=stage-2 /opt/lion/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /opt/lion

ARG VERSION
ENV VERSION=${VERSION}

VOLUME /opt/lion/data

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 8081

STOPSIGNAL SIGQUIT

CMD [ "supervisord", "-c", "/etc/supervisor/supervisord.conf" ]
