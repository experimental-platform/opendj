#!/usr/bin/env bash

set -eu
set -o pipefail

set +x

exec ldapsearch --port 1389 --bindDN "cn=directory manager" --bindPassword password --baseDN 'dc=example,dc=com' "(objectclass=*)"
