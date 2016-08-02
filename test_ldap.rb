require 'minitest'
require 'minitest/autorun'
require 'bundler'
Bundler.require :default

class LdapTest < MiniTest::Test
  LDAP_ADMIN_PASSWORD = 'protonet'
  PASSWORD = 'helloworld'

  def ldap
    @ldap ||= Net::LDAP.new(host: 'localhost', port: 389)
  end

  def test_admin_connect
    ldap.auth "cn=admin,dc=protonet,dc=com", LDAP_ADMIN_PASSWORD
    assert ldap.bind, "Admin should be able to authenticate against LDAP"
  end

  def test_user_authenticate
    ldap.auth "uid=setup.user,ou=People,dc=protonet,dc=com", PASSWORD
    assert ldap.bind, "Regular user should be able to authenticate directly against LDAP"
  end

  def test_unpermitted_user_app_authenticate
    ldap.auth "uid=gitlab,ou=Apps,dc=protonet,dc=com", "demo"
    result = ldap.bind_as(
      base: "ou=People,dc=protonet,dc=com",
      filter: "(mail=noapp@example.com)",
      password: PASSWORD
    )
    refute result, "Unauthorized user should not be granted access to app"
  end

  def test_permitted_user_app_authenticate
    ldap.auth "uid=gitlab,ou=Apps,dc=protonet,dc=com", "demo"
    result = ldap.bind_as(
      base: "ou=People,dc=protonet,dc=com",
      filter: "(mail=somedude@example.com)",
      password: PASSWORD
    )
    assert result, "Authorized user should be granted access to app"
  end
end
