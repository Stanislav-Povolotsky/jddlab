#!/bin/sh
# jddlab container entrypoint.
#
# JDDLAB_ADB_SERVER=<host>[:<port>]
#   Use an ADB server running OUTSIDE the container (normally the host's one,
#   host.docker.internal:5037) instead of starting a private one inside every
#   container. The entrypoint forwards 127.0.0.1:5037 to it, so adb, frida -U,
#   objection, apk-patcher, ... transparently see the devices attached to the host
#   (USB or Wi-Fi), and the connection survives between `docker run --rm` calls
#   (important for one-shot commands and the MCP server). The jddlab launcher and
#   the MCP server set this automatically when a host ADB server is running.

if [ -n "$JDDLAB_ADB_SERVER" ]; then
    case "$JDDLAB_ADB_SERVER" in
        *:*) adb_host=${JDDLAB_ADB_SERVER%:*}; adb_port=${JDDLAB_ADB_SERVER##*:} ;;
        *)   adb_host=$JDDLAB_ADB_SERVER;      adb_port=5037 ;;
    esac
    # Ports opened with `adb forward` live where the ADB server runs (the host):
    # tools that connect to them (android-unpinner) use this address.
    export JDDLAB_ADB_FORWARD_HOST="${JDDLAB_ADB_FORWARD_HOST:-$adb_host}"
    if ! nc -z 127.0.0.1 5037 2>/dev/null; then
        socat TCP-LISTEN:5037,bind=127.0.0.1,reuseaddr,fork "TCP:$adb_host:$adb_port" >/dev/null 2>&1 &
        # Wait (up to ~2s) until the forwarder accepts connections
        i=0
        while [ $i -lt 20 ] && ! nc -z 127.0.0.1 5037 2>/dev/null; do
            sleep 0.1
            i=$((i + 1))
        done
    fi
fi

if [ "$#" -eq 0 ]; then
    set -- bash
fi
exec "$@"
