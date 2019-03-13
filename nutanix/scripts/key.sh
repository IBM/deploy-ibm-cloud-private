#!/bin/bash
# sample script to get a RHEL registration key from a pool
# warning: designed to run on a RHEL host only

REGHOST="replace_with_your_rhel_key_pool_host_url"

if [[ -z "$REGUSER" ]] ; then
    echo -n "User ID: "
    read REGUSER
    if [[ -z "$REGUSER" ]] ; then
        cat <<EOF
Missing userid.
EOF
        exit 1
    fi
fi
if [[ -z "$REGPASS" ]] ; then
    echo -n "Password for $REGUSER: "
    stty -echo
    read -r REGPASS
    stty echo
    echo
    if [[ -z "$REGPASS" ]] ; then
        cat <<EOF
Missing password.
EOF
        exit 1
    fi
fi
REGUSERENC=$(echo $REGUSER | sed s/@/%40/g)
REGPASSENC=$(echo $REGPASS | od -tx1 -An | tr -d '\n' | sed 's/ /%/g')
curl -ks $REGHOST -H "Content-Type: text/xml" -d "<?xml version='1.0' encoding='UTF-8'?><methodCall><methodName>user.create_activation_key</methodName> <params><param><value>$REGUSERENC</value></param> <param><value>$REGPASSENC</value></param> </params> </methodCall>" | grep -oPm1 "(?<=<string>)[^<]+"
