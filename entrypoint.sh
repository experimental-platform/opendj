#!/usr/bin/env bash

set -eu
set -o pipefail

save_master_password() {
	local MASTER_PASSWORD="$1"
	curl --silent --fail -X PUT -d "value=$MASTER_PASSWORD" 'http://skvs/system/ldap_master_password' > /dev/null
	sed "s/INSERT_MASTER_PASSWORD_HERE/$MASTER_PASSWORD/" -i /opt/opendj-install.properties
}

generate_master_password() {
	dd if=/dev/urandom bs=1k count=1 2>/dev/null | sha256sum -b | cut -f1 -d ' '
}

do_initial_config() {
	local MASTER_PASSWORD="$(generate_master_password)"
	save_master_password "$MASTER_PASSWORD"

	/opt/opendj/setup --cli --propertiesFilePath /opt/opendj-install.properties --acceptLicense --no-prompt --doNotStart --ldifFile /initial.ldif

	/opt/opendj/bin/start-ds

	# Remove default permissice ACI
	/opt/opendj/bin/dsconfig -h localhost -p 4444 --bindDN "cn=directory manager" --bindPassword "$MASTER_PASSWORD" --trustAll --no-prompt set-access-control-handler-prop --remove 'global-aci:(targetattr!="userPassword||authPassword||debugsearchindex||changes||changeNumber||changeType||changeTime||targetDN||newRDN||newSuperior||deleteOldRDN")(version 3.0; acl "Anonymous read access"; allow (read,search,compare) userdn="ldap:///anyone";)'

	/opt/opendj/bin/dsconfig -h localhost -p 4444 --bindDN "cn=directory manager" --bindPassword "$MASTER_PASSWORD" --trustAll --no-prompt set-access-control-handler-prop --remove 'global-aci:(targetcontrol="2.16.840.1.113730.3.4.2 || 2.16.840.1.113730.3.4.17 || 2.16.840.1.113730.3.4.19 || 1.3.6.1.4.1.4203.1.10.2 || 1.3.6.1.4.1.42.2.27.8.5.1 || 2.16.840.1.113730.3.4.16 || 1.2.840.113556.1.4.1413 || 1.3.6.1.4.1.36733.2.1.5.1") (version 3.0; acl "Anonymous control access"; allow(read) userdn="ldap:///anyone";)'

	/opt/opendj/bin/dsconfig -h localhost -p 4444 --bindDN "cn=directory manager" --bindPassword "$MASTER_PASSWORD" --trustAll --no-prompt set-access-control-handler-prop --remove 'global-aci:(extop="1.3.6.1.4.1.26027.1.6.1 || 1.3.6.1.4.1.26027.1.6.3 || 1.3.6.1.4.1.4203.1.11.1 || 1.3.6.1.4.1.1466.20037 || 1.3.6.1.4.1.4203.1.11.3") (version 3.0; acl "Anonymous extended operation access"; allow(read) userdn="ldap:///anyone";)'

	# enable REST API
	/opt/opendj/bin/dsconfig -h localhost -p 4444 --bindDN "cn=directory manager" --bindPassword "$MASTER_PASSWORD" --trustAll --no-prompt set-connection-handler-prop --handler-name "HTTP Connection Handler" --set enabled:true

	/opt/opendj/bin/stop-ds
}

if [ ! -f /opt/opendj/config/config.ldif ]; then
	do_initial_config
fi

mkdir -p /opt/opendj/locks

exec /opt/opendj/bin/start-ds -N
