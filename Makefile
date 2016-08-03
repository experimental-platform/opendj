ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
.PHONY: build run shell

build:
	docker build -t platform-ldap .

run:
	docker run -it --rm --name ldap -p 389:389 --env-file=.env.example --volume $(ROOT_DIR)/ldif-builder/example-users.json:/etc/ldap/users.json:ro platform-ldap bash

shell:
	docker exec -it ldap bash