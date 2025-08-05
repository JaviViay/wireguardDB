#!/bin/bash

#Variables
wgInt="wg0"
wgConf="/etc/wireguard/${wgInt}.conf"
db="/etc/wireguard/wgPeers.db"
action=$1
peerName="${2^^}"
peerIP="$3"
tableName="$wgInt"
peerIPMask=32

#Create DB if not exists
if [[ ! -f $db ]]; then
    sqlite3 "${db}" <<EOF
CREATE TABLE $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    pubKey TEXT NOT NULL UNIQUE,
    ip TEXT NOT NULL UNIQUE
);
EOF
fi

#Workflow
case "$action" in
    -a)
        #ADD PEER | -a PEER_NAME PEER_IP
        # Check arguments
        if [[ $# -lt 3 ]]; then
            echo "Usage: $0 -a PEER_NAME PEER_IP"
            exit 1
        fi

        #Generate keys
        peerPrivKey=$(wg genkey)
        peerPubKey=$(echo "$peerPrivKey" | wg pubkey)

        #Insert into DB
        sqlite3 "$db" <<EOF
INSERT INTO $tableName (name, pubKey, ip)
VALUES ('$peerName', '$peerPubKey', '$peerIP');
EOF

        #Insert into .conf
        if [[ $? -eq 1 ]]; then
        exit 1
        fi
        cat <<EOF >> "$wgConf"

[Peer] #$peerName
PublicKey = $peerPubKey
AllowedIPs = $peerIP/$peerIPMask
EOF

        #Share peer privKey once
        echo "$peerName Private Key: $peerPrivKey"
        ;;
    -d)
        #DELETE PEER | -d PEER_NAME
        # Check arguments
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 -d PEER_NAME"
            exit 1
        fi

        #Read pubKey and IP
        read peerPubKey peerIP < <(sqlite3 "$db" "SELECT pubKey, ip FROM $tableName WHERE name = '$peerName';")

        if [[ -z $peerPubKey ]]; then
            echo "Peer $peerName not found"
            exit 1
        fi

        #Delete from .conf
        awk -v peer="#$peerName" '
        BEGIN { skip = 0 }
        /\[Peer\]/ {
            if ($0 ~ peer) {
                skip = 1
                next
            }
        }
        /^\s*\[Peer\]/ && skip == 1 {
            skip = 0
        }
        skip == 0 { print }
        ' "$wgConf" > "${wgConf}.tmp" && mv "${wgConf}.tmp" "$wgConf"

        #Delete from DB
        sqlite3 "$db" "DELETE FROM $tableName WHERE name = '$peerName';"
        ;;

    -l)
        #LIST PEERS | -l
        sqlite3 "$db" <<EOF
.headers on
.mode column
SELECT id, name, ip FROM $wgInt;
EOF
        ;;

    *)
        echo "Unexpected action $action"
        echo "Usage: $0 -a NAME IP | -d NAME"
        exit 1
        ;;
esac