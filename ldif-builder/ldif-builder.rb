require 'bundler'
Bundler.require :default
require 'json'

class User
  def self.from_json_file(path)
    JSON.load(File.read(path)).map do |attributes| 
      new attributes
    end
  end

  include Virtus.model

  attribute :uid, String
  attribute :email, String
  attribute :name, String
  attribute :password, String

  attribute :groups, Array[String]
  attribute :apps, Array[String]

  def initialize(attributes={})
    super attributes

    apps << 'gitlab' unless apps.include? 'gitlab'
  end
end

module Render
  class << self
    def all(users)
      [].tap do |output|
        output << Render.base

        groups = users.map(&:groups).flatten.uniq.compact.sort
        apps   = users.map(&:apps).flatten.uniq.compact.sort

        users.each do |user|
          output << Render.user(user)
        end

        groups.each do |group|
          output << Render.group(group, members: users.select {|u| u.groups.include? group })
        end

        apps.each do |app|
          output << Render.app(app, members: users.select {|u| u.apps.include? app })
        end
      end.join("\n\n")
    end

    def base
      Mustache.render template('base')
    end

    def user(user)
      Mustache.render template('user'), 
        uid: user.uid, 
        email: user.email, 
        name: user.name, 
        password: user.password
    end

    def group(name, members:)
      Mustache.render template('group'), name: name, members: members
    end

    def app(name, members:)
      Mustache.render template('app'), name: name, members: members
    end

    def template(name)
      File.read(File.join(File.dirname(__FILE__), 'templates', "#{name}.ldif.mustache"))
    end
  end
end

if File.expand_path($0) == File.expand_path(__FILE__)
  begin
    path = ARGV[0] || ''
    puts Render.all(User.from_json_file(path))
  rescue => err
    STDERR.puts "Usage: #{__FILE__} path/to/users.json"
    STDERR.puts "  ERROR: #{err.class} - #{err.to_s}"
    err.backtrace.each {|l| puts "    #{l}" }
    exit 1
  end
end