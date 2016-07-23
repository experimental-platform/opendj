require 'net/ldap'
require 'minitest'
require 'minitest/autorun'

class LdapTest < MiniTest::Test
  def ldap
    @ldap ||= Net::LDAP.new(host: 'localhost', port: 389)
  end

  def test_admin_connect
    ldap.auth "cn=admin,dc=protonet,dc=com", "foobar"
    assert ldap.bind, "Admin should be able to authenticate against LDAP"
  end

  def test_user_authenticate
    ldap.auth "uid=protonet1,ou=People,dc=protonet,dc=com", "Changeme!123"
    assert ldap.bind, "Regular user should be able to authenticate directly against LDAP"
  end

  def test_unpermitted_user_app_authenticate
    ldap.auth "uid=gitlab,ou=Apps,dc=protonet,dc=com", "demo"
    result = ldap.bind_as(
      base: "ou=People,dc=protonet,dc=com",
      filter: "(mail=noapp@example.com)",
      password: "Changeme!123"
    )
    refute result, "Unauthorized user should not be granted access to app"
  end

  def test_permitted_user_app_authenticate
    ldap.auth "uid=gitlab,ou=Apps,dc=protonet,dc=com", "demo"
    result = ldap.bind_as(
      base: "ou=People,dc=protonet,dc=com",
      filter: "(mail=somedude@example.com)",
      password: "Changeme!123"
    )
    assert result, "Authorized user should be granted access to app"
  end
end
