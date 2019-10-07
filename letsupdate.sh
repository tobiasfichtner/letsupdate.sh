#!/usr/bin/env bash

## Information
# Uberspace 6 - Let’s Encrypt Update Script for added Domains
# @author Tobias Fichtner <fichtner@circinus.uberspace.de>

## Settings
#
# User Settings
TMP_LIST_PASSWD=( $(getent passwd `/usr/bin/id -un` | sed 's/:/ /g' ))
USERNAME=${TMP_LIST_PASSWD[0]}
HOMEDIR=${TMP_LIST_PASSWD[4]}
USERIPv4=$(dig $USERNAME.$HOSTNAME A +short | grep -Eo '[0-9\.]{7,15}' | head -1)
USERIPv6=$(dig $USERNAME.$HOSTNAME AAAA +short | grep -Eo '[0-9A-Fa-f\:]{7,45}' | head -1)

# Let’s Encrypt Settings
LETSSHARE="$HOMEDIR/.local/share/letsencrypt"
LETSWORK="$LETSSHARE/work/"
LETSCONFIG="$HOMEDIR/.config/letsencrypt"
LETSLOG="$LETSSHARE/logs/"
LETSLIVE="$LETSCONFIG/live"
LETSCHALLANGE="/var/www/virtual/$USERNAME/html/"
LETSRSA=4096
LETSVALIDDAYS=5

## certificate function
#
# order or renew a cert and add it
function certificate ( ) {
        /usr/local/bin/letsencrypt certonly \
                -d $1 \
                --agree-tos \
                --non-interactive \
                -m "$USERNAME@$HOSTNAME" \
                --rsa-key-size="$LETSRSA"  \
                --config-dir="$LETSCONFIG" \
                --work-dir="$LETSWORK" \
                --logs-dir="$LETSLOG" \
                --webroot \
                -w="$LETSCHALLANGE" \
                --key-path "$LETSLIVE/$1/privkey.pem" \
                --cert-path "$LETSLIVE/$1/cert.pem" \
                --post-hook "/usr/local/bin/uberspace-add-certificate -k \"$LETSLIVE/$1/privkey.pem\" -c \"$LETSLIVE/$1/cert.pem\""
}

function getIPv4 ( ) {
        echo `dig $1 A +short | grep -Eo '[0-9\.]{7,15}' | head -1`
}

function getIPv6 ( ) {
        echo `dig $1 AAAA +short | grep -Eo '[0-9A-Fa-f\:]{7,45}' | head -1`
}

#
## update loop
#

for domain in `/usr/local/bin/uberspace-list-domains -w | grep -v "*.$USERNAME.$HOSTNAME"`; do
        cert="$LETSLIVE/$domain/cert.pem"
        if [ $USERIPv4 == "$(getIPv4 $domain)" ] || [ $USERIPv6 == "$(getIPv6 $domain)" ];then
            if [ -f $cert ]; then
                    openssl x509 -checkend $(( $LETSVALIDDAYS * 86400 )) -in $cert > /dev/null
                    if [ $? != 0 ]; then
                            echo
                            certificate $domain
                    fi
            else
                    echo
                    certificate $domain
            fi
        else
            echo
            echo "removing not linked domain: $domain"
            /usr/local/bin/uberspace-del-domain -w -d $domain
        fi
        wait
done
