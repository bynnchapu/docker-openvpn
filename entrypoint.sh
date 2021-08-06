#!/bin/sh

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

OVPN_SERVER=${OVPN_SERVER:-10.8.0.0}

OVPN_NATDEVICE=$(ip addr | awk 'match($0, /global [[:alnum:]]+/) {print substr($0, RSTART+7, RLENGTH)}')
if [ -z "${OVPN_NATDEVICE}" ]; then
    ip addr
    echo "Failed to extract OVPN_NATDEVICE."
    exit 1
fi

iptables -t nat -C POSTROUTING -s ${OVPN_SERVER}/24 -o ${OVPN_NATDEVICE} -j MASQUERADE || {
    iptables -t nat -A POSTROUTING -s ${OVPN_SERVER}/24 -o ${OVPN_NATDEVICE} -j MASQUERADE
}

/usr/sbin/openvpn \
    --cd ${OVPN_DIR:-/etc/openvpn} \
    \
    --port  ${OVPN_PORT:-1194} \
    --proto ${OVPN_PROTO:-udp4} \
    --dev   ${OVPN_DEV:-tun} \
    --cipher AES-256-GCM \
    --data-ciphers AES-256-GCM \
    --topology subnet \
    \
    --ca    ${OVPN_CA:-"/opt/easy-rsa/pki/ca.crt"} \
    --cert  ${OVPN_CERT:-"/opt/easy-rsa/pki/issued/server.crt"} \
    --key   ${OVPN_KEY:-"/opt/easy-rsa/pki/private/server.key"} \
    --dh    ${OVPN_DH:-"/opt/easy-rsa/pki/dh.pem"} \
    --tls-auth /opt/easy-rsa/pki/ta.key 0 \
    \
    --server ${OVPN_SERVER} ${OVPN_SERVER_MASK:-255.255.255.0} \
    --ifconfig-pool-persist ipp.txt \
    --push "route ${OVPN_SERVER} 255.255.0.0" \
    --push "route ${OVPN_HOST_NW:-192.168.0.0} 255.255.255.0" \
    --push "dhcp-option DNS ${OVPN_DNS_SERVER:-1.1.1.1}" \
    \
    --keepalive 10 120 \
    --user nobody \
    --group nobody \
    --persist-key \
    --persist-tun \
    \
    --status openvpn-status.log \
    --verb ${OVPN_VERB:-3} \
    \
    --tun-mtu 1500 \
    --mssfix 1460