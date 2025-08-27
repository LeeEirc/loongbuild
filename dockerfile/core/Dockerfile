FROM ghcr.io/loong64/python:3.11-slim-trixie AS stage-1
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

ARG VERSION

RUN --mount=type=bind,source=dist,target=/dist \
    set -e \
    && mkdir -p /opt/jumpserver \
    && tar -xf /dist/core-${VERSION}.tar.gz -C /opt/jumpserver --strip-components=1 \
    && chown -R root:root /opt/jumpserver \
    && echo > /opt/jumpserver/config.yml \
    && rm -f /opt/*.tar.gz

WORKDIR /opt/jumpserver

ENV PIP_EXTRA_INDEX_URL=https://gitlab.com/api/v4/projects/65746188/packages/pypi/simple
ENV UV_EXTRA_INDEX_URL=https://gitlab.com/api/v4/projects/65746188/packages/pypi/simple

RUN --mount=type=cache,target=/root/.cache \
    set -e \
    && pip install -U pip \
    && pip install uv \
    && uv venv /opt/py3 \
    && . /opt/py3/bin/activate \
    && uv pip install -r pyproject.toml \
    && uv pip install xmlsec==1.3.16 \
    && uv pip install -U lxml

FROM ghcr.io/loong64/python:3.11-slim-trixie
ENV LANG=en_US.UTF-8 \
    PATH=/opt/py3/bin:$PATH

ARG DEPENDENCIES="                    \
        bubblewrap                    \
        ca-certificates               \
        openssh-client                \
        sshpass"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -e \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES} \
    && mkdir -p /root/.ssh/ \
    && echo "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n\tCiphers +aes128-cbc\n\tKexAlgorithms +diffie-hellman-group1-sha1\n\tHostKeyAlgorithms +ssh-rsa" > /root/.ssh/config

COPY --from=stage-1 /usr/local/bin /usr/local/bin
COPY --from=stage-1 /opt/jumpserver /opt/jumpserver
COPY --from=stage-1 /opt/jumpserver/apps/libs/ansible/ansible.cfg /etc/ansible/
COPY --from=stage-1 /opt/py3 /opt/py3

WORKDIR /opt/jumpserver

ARG VERSION
ENV VERSION=${VERSION}

VOLUME /opt/jumpserver/data

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 8080

STOPSIGNAL SIGQUIT

CMD ["start", "all"]
