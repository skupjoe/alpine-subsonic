FROM alpine

MAINTAINER paganini@paganini.net

ARG SUBSONIC_UID=1000
ARG SUBSONIC_GID=1000
ARG SUBSONIC_BIN=/var/subsonic/bin
ARG SUBSONIC_DATA=/var/subsonic/data
ARG SUBSONIC_MEDIA=/var/subsonic/media
ARG SUBSONIC_VERSION=6.1.6

ENV SUBSONIC_UID=${SUBSONIC_UID} \
    SUBSONIC_GID=${SUBSONIC_GID} \
    SUBSONIC_BIN=${SUBSONIC_BIN} \
    SUBSONIC_DATA=${SUBSONIC_DATA} \
    SUBSONIC_MEDIA=${SUBSONIC_MEDIA} \
    SUBSONIC_VERSION=${SUBSONIC_VERSION}

# Add subsonic tar.gz
ADD https://sourceforge.net/projects/subsonic/files/subsonic/${SUBSONIC_VERSION}/subsonic-${SUBSONIC_VERSION}-standalone.tar.gz/download /tmp/subsonic.tar.gz

# - Create a new group 'subsonic' with SUBSONIC_GID, data $SUBSONIC_DATA
# - Create user 'subsonic' with SUBSONIC_UID, add to that group.
# - Create $SUBSONIC_BIN & set permissions on $SUBSONIC_BIN
# - Create $SUBSONIC_DATA & set permissions on $SUBSONIC_DATA
# - Untar the subsonic tar file into $SUBSONIC_BIN
RUN addgroup -g $SUBSONIC_GID subsonic && \
    adduser -D -H -h $SUBSONIC_BIN -u $SUBSONIC_UID -G subsonic -g "Subsonic User" subsonic && \
    mkdir -p $SUBSONIC_BIN && \
    if [ ! -d "$SUBSONIC_DATA" ]; then \
        mkdir -p $SUBSONIC_DATA && \
        chown -R subsonic $SUBSONIC_DATA && \
        chmod 0770 $SUBSONIC_DATA; \
    fi && \
    tar zxvf /tmp/subsonic.tar.gz -C $SUBSONIC_BIN && \
    rm -f /tmp/*.tar.gz && \
    chown -R subsonic $SUBSONIC_BIN && \
    chmod 0770 $SUBSONIC_BIN

# Create subsonic media directory ($SUBSONIC_MEDIA) if it doesn't already exist.
RUN if [ ! -d "$SUBSONIC_MEDIA" ]; then \
        echo mkdir -p $SUBSONIC_MEDIA && \
        echo chown -R subsonic $SUBSONIC_MEDIA && \
        echo chmod 0770 $SUBSONIC_MEDIA; \
    fi

# Install java8, ffmpeg, lame & friends.
RUN apk --update add openjdk8-jre ffmpeg

# Create hardlinks to the transcoding binaries so we can mount a volume
# over $SUBSONIC_DATA. If you mount a volume over $SUBSONIC_DATA, create
# symlinks on the host.
#
# TODO: Investigate a better way to do this.
RUN if [ ! -d "$SUBSONIC_DATA/transcode" ]; then \
        mkdir -p $SUBSONIC_DATA/transcode && \
        ln /usr/bin/ffmpeg /usr/bin/lame $SUBSONIC_DATA/transcode; \
    fi

VOLUME $SUBSONIC_DATA

EXPOSE 4040

USER subsonic

COPY startup.sh /startup.sh

CMD []
ENTRYPOINT ["/startup.sh"]
