BASE_LDIF_STRUCTURE = <<LDIF
dn: ou=People,dc=protonet,dc=com
objectClass: top
objectClass: organizationalUnit
ou: People

# The list of apps
dn: ou=Apps,dc=protonet,dc=com
objectClass: top
objectClass: organizationalUnit
ou: Apps

dn: ou=Groups,dc=protonet,dc=com
objectClass: organizationalunit
objectClass: top
ou: Groups

dn: ou=AppMemberships,dc=protonet,dc=com
objectClass: organizationalunit
objectClass: top
ou: AppMemberships
LDIF

USER_LDIF_TEMPLATE = <<LDIF
dn: uid=%{uid},ou=People,dc=protonet,dc=com
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
givenName: %{uid}
sn: %{uid}
cn: %{name}
uid: %{uid}
userPassword: %{password}
mail: %{email}
LDIF

GROUP_LDIF_TEMPLATE = <<LDIF
dn: cn=%{name},ou=Groups,dc=protonet,dc=com
cn: %{name}
objectClass: groupOfNames
objectClass: top
ou: Groups
%{members}
LDIF

APP_LDIF_TEMPLATE = <<LDIF
dn: uid=%{name},ou=Apps,dc=protonet,dc=com
objectClass: top
objectClass: inetOrgPerson
userPassword: %{password}
sn: %{name}
cn: %{name}
uid: %{name}

# TODO: Create ACL setting, currently failing :(
# dn: ou=People,dc=protonet,dc=com
# changetype: modify
# add: aci
# aci: (targetattr!="userPassword")(target="ldap:///uid=*,ou=People,dc=protonet,dc=com")(targetfilter="(isMemberOf=cn=%{name},ou=AppMemberships,dc=protonet,dc=com)")(version 3.0; acl "%{name} access to its users"; allow(all) userdn="ldap:///uid=%{name},ou=Apps,dc=protonet,dc=com";)
LDIF

APP_MEMBERSHIP_LDIF_TEMPLATE = <<LDIF
dn: cn=%{name},ou=AppMemberships,dc=protonet,dc=com
cn: %{name}
objectClass: groupOfNames
objectClass: top
ou: AppMemberships
%{members}
LDIF


class User
  attr_reader :email, :uid, :name, :groups, :apps
  def initialize(email:, uid:, name:, groups: [], apps: [])
    @email, @uid, @name, @groups, @apps = email, uid, name, groups, apps
  end

  alias_method :sn, :uid

  def password
    # helloworld, hashed with unix_crypt sha512, see http://www.openldap.org/faq/data/cache/1467.html
    "{CRYPT}$6$jkTeJq/ISmxqM5o8$5x9zecfLzhSQGpliIqFVivIVPsMgcpuGJoERV23VtcC471GthduMTe.mvY6vEk6ot/M562i8e91LWZ5LuCPJ01"
  end

  def to_ldif
    USER_LDIF_TEMPLATE % { uid: uid, name: name, email: email, password: password}
  end

  def to_membership
    "member: uid=#{uid},ou=People,dc=protonet,dc=com"
  end
end

users = [
  User.new(email: 'setupuser@example.com', name: 'Box Admin', uid: 'setup.user', groups: ["Administrators"], apps: ["gitlab"]),
  User.new(email: 'somedude@example.com', name: 'Box Dude', uid: 'some.dude', apps: ["gitlab"]),
  User.new(email: 'noapp@example.com', name: 'Box Noapp Gal', uid: 'no.app')
]

puts "# ======== BEGIN BASE CONFIG ========"
puts BASE_LDIF_STRUCTURE
puts "# ======== END BASE CONFIG ========"
puts
puts "# ======== BEGIN USERS ========"
puts users.map(&:to_ldif).join("\n")
puts "# ======== END USERS ========"

users.map(&:groups).flatten.uniq.each do |group|
  members = users.select {|u| u.groups.include? group }
  puts
  puts "# ======== BEGIN GROUP: #{group} ========"
  puts GROUP_LDIF_TEMPLATE % { name: group, members: members.map(&:to_membership).join("\n") }
  puts "# ======== END GROUP: #{group} ========"
end

apps = %w(gitlab)

apps.each do |app|
  puts
  puts "# ======== BEGIN APP: #{app} ========"
  puts APP_LDIF_TEMPLATE % { name: app, password: 'demo' }
  puts
  members = users.select {|u| u.apps.include? app }
  puts APP_MEMBERSHIP_LDIF_TEMPLATE % { name: app, members: members.map(&:to_membership).join("\n") }
  puts "# ======== END APP: #{app} ========"
end
