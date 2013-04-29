# -*- ruby -*-

require 'rubygems'
require 'hoe'

# Don't turn on warnings, output is very ugly w/ generated code
Hoe::RUBY_FLAGS.sub! /-w/, ''
# Add stark to path if we have it checked out locally
stark_local_path = File.expand_path('../../stark/lib', __FILE__)
Hoe::RUBY_FLAGS.concat " -I#{stark_local_path}" if File.directory?(stark_local_path)

Hoe.plugin :git
Hoe.plugin :gemspec

Hoe.spec 'stark-rack' do
  developer('Evan Phoenix', 'evan@phx.io')
  dependency 'stark', '< 2.0.0'
  dependency 'rack', '>= 1.5.0', :dev
end

# vim: syntax=ruby
