.PHONY: build run shell

build:
	docker build -t platform-ldap .

run:
	docker run -it --rm --name ldap -p 389:389 --env-file=.env.example platform-ldap bash

shell:
	docker exec -it ldap bash