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

# Let’s Encrypt Settings
LETSSHARE="$HOMEDIR/.local/share/letsencrypt"
LETSWORK="$LETSSHARE/work/"
LETSCONFIG="$HOMEDIR/.config/letsencrypt"
LETSLOG="$LETSSHARE/logs/"
LETSLIVE="$LETSCONFIG/live/"
LETSCHALLANGE="/var/www/virtual/$USERNAME/html/"
LETSRSA=4096
LETSVALIDDAYS=5

## certificate function
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
                --cert-path "$LETSLIVE/$1/cert.pem \
                --post-hook "/usr/local/bin/uberspace-add-certificate -k \"$LETSLIVE/$1/privkey.pem\" -c \"$LETSLIVE/$1/cert.pem\""
}

#
## update loop
#


for domain in `/usr/local/bin/uberspace-list-domains -w | grep -v "*.$USERNAME.$HOSTNAME"`; do
        cert="$LETSLIVE$domain/cert.pem"
        if [ -f $cert ]; then
                openssl x509 -checkend $(( $LETSVALIDDAYS * 86400 )) -in $cert > /dev/null
                if [ $? != 0 ]; then
                        certificate $domain
                fi
        else
                certificate $domain
        fi
done
