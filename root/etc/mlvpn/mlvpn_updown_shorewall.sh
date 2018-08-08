#!/bin/sh

# up/down script for MLVPN.
#
# MLVPN calls this script with at least 2 arguments:
# $1 : interface name
# $2 : "command"
# command can be:
#    - "tuntap_up"
#    - "tuntap_down"
#    - "rtun_up" $3 : tunnel name
#    - "rtun_down" $3 : tunnel name
# tuntap_up is called when at least one tunnel is up
# tuntap_down is called when at every tunnel is down
# rtun_up is called when successfully connected
# rtun_down is called when disconnected

# Environment variables are set by mlvpn, reflecting
# settings in mlvpn.conf
# IP4=
# IP6=
# IP4_GATEWAY=
# IP6_GATEWAY=
# IP4_ROUTES=
# IP6_ROUTES=
# MTU=
# DEVICE=

DEVICE="$1"
STATUS="$2"

if [ ! -d /var/log/mlvpn/ ]; then
    mkdir -p /var/log/mlvpn/
fi

NAME=${DEVICE#"mlvpn"}
LOG=/var/log/mlvpn/${NAME}.log

[ -z "$STATUS" ] || [ -z "$DEVICE" ] || [ -z "$MTU" ] && exit 1

unamestr=$(uname)


log()
{
    # make sure log file is readble only from root
    umask 0066

    TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S")
    ECHO="echo ${TIMESTAMP} "
    $ECHO $@ >> $LOG
}

link_up()
{
    ip link set dev $DEVICE mtu $MTU up
    if [ ! -z "$IP4" ]; then
        ip -4 addr add $IP4 dev $DEVICE
    fi
    if [ ! -z "$IP6" ]; then
        ip -6 addr add $IP6 dev $DEVICE
    fi
    shorewall enable $DEVICE &> /dev/null
}
link_down()
{
    ip link set dev $DEVICE down
    shorewall disable $DEVICE &> /dev/null
}
route_add()
{
    family=$1
    route=$2
    via=""
    if [ "$family" = "4" ]; then
        [ -z $IP4_GATEWAY ] || via="via $IP4_GATEWAY"
        ip -4 route add $route $via dev $DEVICE
    elif [ "$family" = "6" ]; then
        [ -z $IP6_GATEWAY ] || via="via $IP6_GATEWAY"
        ip -6 route add $route $via dev $DEVICE
    fi
}

[ "$MTU" -gt 1452 ] && (echo "MTU set too high."; exit 1)
[ "$MTU" -lt 100 ] && (echo "MTU set too low."; exit 1)
case "$STATUS" in
    "tuntap_up")
        log "$DEVICE up"
        link_up
        for r in $IP4_ROUTES; do
            route_add 4 $r
        done
        for r in $IP6_ROUTES; do
            route_add 6 $r
        done
    ;;
    "tuntap_down")
        log "$DEVICE down"
        link_down
    ;;
    "rtun_up")
        log "tunnel [$3] is up"
        ;;
    "rtun_down")
        log "tunnel [$3] is down"
        ;;
esac

shorewall restart &> /dev/null

exit 0
