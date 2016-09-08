require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'support/matchers'
require 'chef/application'

RSpec.configure do |c|
  c.filter_run(focus: true)
  c.run_all_when_everything_filtered = true

  c.before(:each) do
    allow_any_instance_of(Chef::Node).to receive(:ingenerator_project_name).and_return('stubproject')
    allow_any_instance_of(Chef::Node).to receive(:node_environment).and_return(:localdev)
    allow_any_instance_of(Chef::Recipe).to receive(:node_environment).and_return(:localdev)
  end
end
