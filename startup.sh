#!/bin/sh -e

###################################################################################
# Shell script for starting Subsonic.  See http://subsonic.org.
#
# Author: Sindre Mehus
#
# Adapted for docker use by Michael Schuerig <michael@schuerig.de>
# Adapted for alpine/docker use by Marco Paganini <paganini@paganini.net>
# Adapted for architectural reasons by Alisson Vassopoli <alisson_vassopoli@hotmail.com>
# Adapted & simplified further by Joseph Skupniewicz <joseph.skup@gmail.com>
#
###################################################################################

SUBSONIC_DATA=${SUBSONIC_DATA:-/var/subsonic/data}
SUBSONIC_MEDIA=${SUBSONIC_MEDIA:-/var/subsonic/media}
SUBSONIC_HOST=${SUBSONIC_HOST:-0.0.0.0}
SUBSONIC_PORT=${SUBSONIC_PORT:-4040}
SUBSONIC_HTTPS_PORT=${SUBSONIC_HTTPS_PORT:-0}
SUBSONIC_CONTEXT_PATH=${SUBSONIC_CONTEXT_PATH:-/}
SUBSONIC_DB=${SUBSONIC_DB}
SUBSONIC_MAX_MEMORY=${SUBSONIC_MAX_MEMORY:-200}
SUBSONIC_PIDFILE=${SUBSONIC_PIDFILE}
SUBSONIC_DEFAULT_MUSIC_FOLDER=${SUBSONIC_DEFAULT_MUSIC_FOLDER:-${SUBSONIC_MEDIA}/music}
SUBSONIC_DEFAULT_PODCAST_FOLDER=${SUBSONIC_DEFAULT_PODCAST_FOLDER:-${SUBSONIC_MEDIA}/podcasts}
SUBSONIC_DEFAULT_PLAYLIST_FOLDER=${SUBSONIC_DEFAULT_PLAYLIST_FOLDER:-${SUBSONIC_MEDIA}/playlists}

SUBSONIC_USER=subsonic

export LANG=POSIX
export LC_ALL=en_US.UTF-8

quiet=0

usage() {
    echo "Usage: subsonic.sh [options]"
    echo "  --help               This small usage guide."
    echo "  --home=DIR           The directory where Subsonic will create files."
    echo "                       Make sure it is writable. Default: /var/subsonic"
    echo "  --host=HOST          The host name or IP address on which to bind Subsonic."
    echo "                       Only relevant if you have multiple network interfaces and want"
    echo "                       to make Subsonic available on only one of them. The default value"
    echo "                       will bind Subsonic to all available network interfaces. Default: 0.0.0.0"
    echo "  --port=PORT          The port on which Subsonic will listen for"
    echo "                       incoming HTTP traffic. Default: 4040"
    echo "  --https-port=PORT    The port on which Subsonic will listen for"
    echo "                       incoming HTTPS traffic. Default: 0 (disabled)"
    echo "  --context-path=PATH  The context path, i.e., the last part of the Subsonic"
    echo "                       URL. Typically '/' or '/subsonic'. Default '/'"
    echo "  --db=JDBC_URL        Use alternate database. MySQL, PostgreSQL and MariaDB are currently supported."
    echo "  --max-memory=MB      The memory limit (max Java heap size) in megabytes."
    echo "                       Default: 100"
    echo "  --pidfile=PIDFILE    Write PID to this file. Default not created."
    echo "  --quiet              Don't print anything to standard out. Default false."
    echo "  --default-music-folder=DIR    Configure Subsonic to use this folder for music.  This option "
    echo "                                only has effect the first time Subsonic is started. Default '/var/music'"
    echo "  --default-podcast-folder=DIR  Configure Subsonic to use this folder for Podcasts.  This option "
    echo "                                only has effect the first time Subsonic is started. Default '/var/music/Podcast'"
    echo "  --default-playlist-folder=DIR Configure Subsonic to use this folder for playlists.  This option "
    echo "                                only has effect the first time Subsonic is started. Default '/var/playlists'"
    exit 1
}


# Parse arguments.
while [ $# -ge 1 ]; do
    case $1 in
        debug)
            exec /bin/sh
            ;;
        --help)
            usage
            ;;
        --home=?*)
            SUBSONIC_DATA=${1#--home=}
            ;;
        --host=?*)
            SUBSONIC_HOST=${1#--host=}
            ;;
        --port=?*)
            SUBSONIC_PORT=${1#--port=}
            ;;
        --https-port=?*)
            SUBSONIC_HTTPS_PORT=${1#--https-port=}
            ;;
        --context-path=?*)
            SUBSONIC_CONTEXT_PATH=${1#--context-path=}
            ;;
        --db=?*)
            SUBSONIC_DB=${1#--db=}
            ;;
        --max-memory=?*)
            SUBSONIC_MAX_MEMORY=${1#--max-memory=}
            ;;
        --pidfile=?*)
            SUBSONIC_PIDFILE=${1#--pidfile=}
            ;;
        --quiet)
            quiet=1
            ;;
        --default-music-folder=?*)
            SUBSONIC_DEFAULT_MUSIC_FOLDER=${1#--default-music-folder=}
            ;;
        --default-podcast-folder=?*)
            SUBSONIC_DEFAULT_PODCAST_FOLDER=${1#--default-podcast-folder=}
            ;;
        --default-playlist-folder=?*)
            SUBSONIC_DEFAULT_PLAYLIST_FOLDER=${1#--default-playlist-folder=}
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Owning in case of another user associated due to some sync strategy
# chown -R subsonic $SUBSONIC_MEDIA

# Create Subsonic home directory.
mkdir -p \
    ${SUBSONIC_DATA} \
    ${SUBSONIC_DEFAULT_MUSIC_FOLDER} \
    ${SUBSONIC_DEFAULT_PODCAST_FOLDER} \
    ${SUBSONIC_DEFAULT_PLAYLIST_FOLDER} \
    /tmp/subsonic

LOG=${SUBSONIC_DATA}/subsonic_sh.log
truncate -s0 ${LOG}


cd $SUBSONIC_BIN

exec /usr/bin/java -Xmx${SUBSONIC_MAX_MEMORY}m \
    -Dsubsonic.home=${SUBSONIC_DATA} \
    -Dsubsonic.host=${SUBSONIC_HOST} \
    -Dsubsonic.port=${SUBSONIC_PORT} \
    -Dsubsonic.httpsPort=${SUBSONIC_HTTPS_PORT} \
    -Dsubsonic.contextPath=${SUBSONIC_CONTEXT_PATH} \
    -Dsubsonic.db="${SUBSONIC_DB}" \
    -Dsubsonic.defaultMusicFolder=${SUBSONIC_DEFAULT_MUSIC_FOLDER} \
    -Dsubsonic.defaultPodcastFolder=${SUBSONIC_DEFAULT_PODCAST_FOLDER} \
    -Dsubsonic.defaultPlaylistFolder=${SUBSONIC_DEFAULT_PLAYLIST_FOLDER} \
    -Djava.awt.headless=true \
    -verbose:gc \
    -jar subsonic-booter-jar-with-dependencies.jar >> ${LOG} 2>&1
