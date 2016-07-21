require 'net/ldap'
require 'pry'

ldap = Net::LDAP.new(host: 'localhost', port: 389)
ldap.auth "cn=admin,dc=protonet,dc=com", "foobar"
if ldap.bind
  puts "Authed"
else
  fail "Could not auth"
end

ldap = Net::LDAP.new(host: 'localhost', port: 389)
ldap.auth "uid=protonet1,ou=People,dc=protonet,dc=com", "Changeme!123"
if ldap.bind
  puts "Authed"
else
  fail "Could not auth"
end