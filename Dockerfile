FROM alpine

MAINTAINER paganini@paganini.net

# Desired UID & GID
ENV SUBSONIC_UID=1000
ENV SUBSONIC_GID=1000
ENV SUBSONIC_BIN=/var/subsonic/bin
ENV SUBSONIC_HOME=/var/subsonic/home
ENV SUBSONIC_DATA=/var/subsonic/media
ENV SUBSONIC_VERSION 6.1.6

# Add subsonic tar.gz
ADD https://sourceforge.net/projects/subsonic/files/subsonic/${SUBSONIC_VERSION}/subsonic-${SUBSONIC_VERSION}-standalone.tar.gz/download /tmp/subsonic.tar.gz

# - Create a new group 'subsonic' with SUBSONIC_GID, home $SUBSONIC_HOME
# - Create user 'subsonic' with SUBSONIC_UID, add to that group.
# - Create $SUBSONIC_BIN
# - Create $SUBSONIC_HOME
# - Untar the subsonic tar file into $SUBSONIC_BIN
# - Set permissions of $SUBSONIC_BIN
# - Set permissions of $SUBSONIC_HOME
RUN addgroup -g $SUBSONIC_GID subsonic && \
    adduser -D -H -h $SUBSONIC_BIN -u $SUBSONIC_UID -G subsonic -g "Subsonic User" subsonic && \
    mkdir -p $SUBSONIC_BIN && \
    mkdir -p $SUBSONIC_HOME && \
    tar zxvf /tmp/subsonic.tar.gz -C $SUBSONIC_BIN && \
    rm -f /tmp/*.tar.gz && \
    chown -R subsonic $SUBSONIC_BIN && \
    chown -R subsonic $SUBSONIC_HOME && \
    chmod 0770 $SUBSONIC_BIN && \
    chmod 0770 $SUBSONIC_HOME

# Create subsonic data directory ($SUBSONIC_DATA). This is where subsonic stores
# its state information. This is normally overriden with --volume, but we create
# it here in case the user prefers to save state in the container itself.
RUN mkdir -p $SUBSONIC_DATA && \
    chown -R subsonic $SUBSONIC_DATA && \
    chmod 0770 $SUBSONIC_DATA

# Install java8, ffmpeg, lame & friends.
RUN apk --update add openjdk8-jre ffmpeg

# Create hardlinks to the transcoding binaries so we can mount a volume
# over $SUBSONIC_HOME. If you mount a volume over $SUBSONIC_HOME, create
# symlinks on the host.
#
# TODO: Investigate a better way to do this.
RUN mkdir -p $SUBSONIC_HOME/transcode && \
    ln /usr/bin/ffmpeg /usr/bin/lame $SUBSONIC_HOME/transcode

VOLUME $SUBSONIC_HOME

EXPOSE 4040

USER subsonic

COPY startup.sh /startup.sh

CMD []
ENTRYPOINT ["/startup.sh"]
