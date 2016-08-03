#!/usr/bin/env bash
# Based on https://github.com/nickstenning/docker-slapd/blob/master/slapd.sh

set -eu
set -o pipefail

status() {
  echo
  echo "-------------> ${@}"
  echo
}

LDAP_ROOTPASS=protonet
LDAP_ORGANISATION=Protonet

: LDAP_ROOTPASS=${LDAP_ROOTPASS}
: LDAP_ORGANISATION=${LDAP_ORGANISATION}

status "Configuring slapd"
cat <<EOF | debconf-set-selections
	slapd slapd/internal/generated_adminpw password ${LDAP_ROOTPASS}
	slapd slapd/internal/adminpw password ${LDAP_ROOTPASS}
	slapd slapd/password2 password ${LDAP_ROOTPASS}
	slapd slapd/password1 password ${LDAP_ROOTPASS}
	slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
	slapd slapd/domain string protonet.com
	slapd shared/organization string ${LDAP_ORGANISATION}
	slapd slapd/backend string HDB
	slapd slapd/purge_database boolean true
	slapd slapd/move_old_database boolean true
	slapd slapd/allow_ldap_v2 boolean false
	slapd slapd/no_configuration boolean false
	slapd slapd/dump_database select when needed
EOF
dpkg-reconfigure -f noninteractive slapd

# Initial import
status "Bootstrapping LDAP database"
ldap_init=/etc/ldap/initialize-protonet.ldif
cd /opt/ldif-builder/ && ruby ldif-builder.rb /etc/ldap/users.json > $ldap_init
slapadd -v -l $ldap_init

status "Launching slapd"
exec /usr/sbin/slapd -h "ldap:///" -u openldap -g openldap -d 1