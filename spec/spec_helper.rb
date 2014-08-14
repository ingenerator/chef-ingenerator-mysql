require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'support/matchers'
require 'chef/application'

RSpec.configure do |c|
  c.filter_run(focus: true)
  c.run_all_when_everything_filtered = true
end
