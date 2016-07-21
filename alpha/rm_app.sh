#!/usr/bin/env bash

set -eu
set -o pipefail

set +x

while [[ $# > 0 ]]; do
	key="$1"
	case $key in
		--uid)
			APPUID="$2"
			shift
		;;
		*)
			echo "Unknown parameter '$key'"
			exit 1
		;;
	esac
	shift
done

#ACI="(targetattr!=\"userPassword\")(target=\"ldap:///uid=*,ou=People,dc=example,dc=com\")(version 3.0; acl \"$APPUID access to its users\"; allow(all) userdn=\"ldap:///uid=$APPUID,ou=Apps,dc=example,dc=com\";)"
ACI="(targetattr!=\"userPassword\")(target=\"ldap:///uid=*,ou=People,dc=example,dc=com\")(targetfilter=\"(isMemberOf=cn=$APPUID,ou=AppMemberships,dc=example,dc=com)\")(version 3.0; acl \"$APPUID access to its users\"; allow(all) userdn=\"ldap:///uid=$APPUID,ou=Apps,dc=example,dc=com\";)"

LDIF="
dn: uid=$APPUID,ou=Apps,dc=example,dc=com
changetype: delete

dn: cn=$APPUID,ou=AppMemberships,dc=example,dc=com
changetype: delete

dn: ou=People,dc=example,dc=com
changetype: modify
delete: aci
aci: $ACI
"

echo "$LDIF"

exec ldapmodify --port 1389 --bindDN "cn=directory manager" --bindPassword password -f <(echo "$LDIF")
