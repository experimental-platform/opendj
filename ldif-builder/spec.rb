require File.join(File.dirname(__FILE__), 'ldif-builder')
require 'securerandom'

RSpec.describe "Ldif Builder" do
  def build_user(uid: SecureRandom.hex(10), email: "#{uid}@example.com", name: uid, password: 'default', groups: nil, apps: nil)
    User.new uid: uid, email: email, name: name, password: password, groups: groups, apps: apps
  end

  def fixture(name)
    File.read File.join(File.dirname(__FILE__), "fixtures", "#{name}.ldif")
  end

  describe Render do
    describe ".all" do
      it "builds the expected LDIF components based upon given users" do
        admin_user = build_user groups: %w(admins)
        app_user = build_user apps: %w(gitlab soul)
        admin_app_user = build_user groups: %w(admins), apps: %w(gitlab)
        nothing_user = build_user

        expect(Render).to receive(:base).and_return("BASE")

        expect(Render).to receive(:user).with(admin_user).and_return("ADMIN_USER")
        expect(Render).to receive(:user).with(app_user).and_return("APP_USER")
        expect(Render).to receive(:user).with(admin_app_user).and_return("ADMIN_APP_USER")
        expect(Render).to receive(:user).with(nothing_user).and_return("NOTHING_USER")

        expect(Render).to receive(:group).with("admins", members: [admin_user, admin_app_user]).and_return("ADMINS")
        expect(Render).to receive(:app).with("gitlab", members: [app_user, admin_app_user]).and_return("GITLAB")
        expect(Render).to receive(:app).with("soul", members: [app_user]).and_return("SOUL")

        # Assert we have called all the expected template renderings and return the assembled
        # resulting LDIF
        expect(Render.all([admin_user, app_user, admin_app_user, nothing_user])).to be == %w(
          BASE
          ADMIN_USER
          APP_USER
          ADMIN_APP_USER
          NOTHING_USER
          ADMINS
          GITLAB
          SOUL
        ).join("\n\n")
      end

      describe ".base" do
        it "renders the base configuration" do
          expect(Render.base).to be == fixture(:base)
        end
      end

      describe ".user" do
        it "renders the given user" do
          user = User.new(uid: 'example.user', email: 'example@example.com', name: 'Foo Bar', password: 'sample')
          expect(Render.user(user)).to be == fixture(:user)
        end
      end

      describe ".group" do
        it "renders the given group and given members" do
          members = [User.new(uid: 'foo'), User.new(uid: 'bar')]
          expect(Render.group('DemoGroup', members: members)).to be == fixture(:group)
        end
      end

      describe ".app" do
        it "renders the given app and given members" do
          members = [User.new(uid: 'foo'), User.new(uid: 'bar')]
          expect(Render.app('DemoApp', members: members)).to be == fixture(:app)
        end
      end
    end
  end

  describe User do
    describe "#uid" do
    end

    describe "#email" do
    end

    describe "#name" do
    end

    describe "#password" do
    end

    describe "#groups" do
      it "is an empty array by default" do
        expect(User.new.groups).to be_empty
      end
    end

    describe "#apps" do
      it "is an empty array by default" do
        expect(User.new.apps).to be_empty
      end
    end
  end
end