require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'support/matchers'
require 'chef/application'

RSpec.configure do |c|
  c.filter_run(focus: true)
  c.run_all_when_everything_filtered = true

  # Default platform / version to mock Ohai data from
  c.platform = 'ubuntu'
  c.version  = '14.04'

  # Don't clear cookbooks from the server-runner between each test for performance
  c.server_runner_clear_cookbooks = false

  c.before(:each) do
    allow_any_instance_of(Chef::Node).to receive(:ingenerator_project_name).and_return('stubproject')
    allow_any_instance_of(Chef::Node).to receive(:node_environment).and_return(:localdev)
    allow_any_instance_of(Chef::Recipe).to receive(:node_environment).and_return(:localdev)
  end

  c.alias_example_group_to :describe_resource, describe_resource: true
end

shared_context 'describe_resource', :describe_resource do
  let (:resource) do
    raise 'Define a `let(:resource)` in your describe_resource block'
  end

  let (:chef_runner) do
    ChefSpec::SoloRunner.new(
      cookbook_path: ['./test/cookbooks', RSpec.configuration.cookbook_path],
      step_into:     [resource]
    ) do |node|
      node_attributes.each do |key, values|
        node.normal[key] = values
      end
    end
  end

  let (:converge_what)   { ["test_helpers::test_#{resource}"] }
  let (:node_attributes) { {} }

  let (:chef_run) do
    chef_runner.converge(*converge_what)
  end
end
