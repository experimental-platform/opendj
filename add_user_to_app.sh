#!/usr/bin/env bash

set -eu
set -o pipefail

set +x

while [[ $# > 0 ]]; do
	key="$1"
	case $key in
		--uid)
			MEMBERUID="$2"
			shift
		;;
		--app)
			APP="$2"
			shift
		;;
		*)
			echo "Unknown parameter '$key'"
			exit 1
		;;
	esac
	shift
done

LDIF="dn: cn=$APP,ou=AppMemberships,dc=example,dc=com
changetype: modify
add: member
member: uid=$MEMBERUID,ou=People,dc=example,dc=com"

exec ldapmodify --port 1389 --bindDN "cn=directory manager" --bindPassword password -f <(echo "$LDIF")
