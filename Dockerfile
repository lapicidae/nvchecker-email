FROM alpine:latest

ARG USERNAME=nvchk \
    GROUPNAME=$USERNAME \
    PUID=1000 \
    PGID=$PUID \
    authors="A. Hemmerle <github.com/lapicidae>" \
    baseDigest \
    dateTime \
    nvcRevision \
    nvcVersion

ENV TZ="UTC"

# copy local files
COPY root/ /

RUN echo "**** install runtime packages ****" && \
    apk add --no-cache --upgrade \
      bash \
      git \
      gzip \
      nvchecker \
      py3-awesomeversion \
      py3-lxml \
      py3-packaging \
      py3-toml \
      runuser \
      shadow \
      tini \
      tzdata \
      yq && \
    echo "*********** set timezone *********" && \
    ln -s /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone && \
    echo "********* set permissions ********" && \
    chmod 755 /usr/local/bin/conf_watch && \
    chmod 755 /usr/local/bin/cron-human && \
    chmod 755 /usr/local/bin/cron_run && \
    chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chmod 755 /usr/local/bin/nvchecker-email && \
    echo "************ link files **********" && \
    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint && \
    echo "******* add group and user *******" && \
    addgroup -g $PGID $GROUPNAME && \
    adduser -D -G $GROUPNAME -u $PUID -h /nvchecker $USERNAME && \
    echo "************ init cron ***********" && \
    crontab -u root -r && \
    crontab -u $USERNAME /defaults/nvchk-cron && \
    echo "************* cleanup ************" && \
    rm -rf /var/cache/apk/*

WORKDIR /nvchecker

LABEL org.opencontainers.image.authors=${authors} \
      org.opencontainers.image.base.digest=${baseDigest} \
      org.opencontainers.image.base.name="docker.io/alpine:latest" \
      org.opencontainers.image.created=${dateTime} \
      org.opencontainers.image.description="new version checker (nvchecker) checks whether a new version of a software has been released and then notifies you by e-mail" \
      org.opencontainers.image.documentation="https://github.com/lapicidae/nvchecker-email/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT AND GPL-2.0-or-later AND GPL-3.0-or-later" \
      org.opencontainers.image.revision=${nvcRevision} \
      org.opencontainers.image.source="https://github.com/lapicidae/nvchecker-email/" \
      org.opencontainers.image.title="nvchecker email" \
      org.opencontainers.image.url="https://github.com/lapicidae/nvchecker-email/blob/master/README.md" \
      org.opencontainers.image.version=${nvcVersion}

VOLUME ["/nvchecker"]

#USER $USERNAME

HEALTHCHECK --interval=20s --timeout=3s \
    CMD ps aux | grep '[c]rond' || exit 1

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint"]
CMD ["crond", "-f", "-l", "8"]
