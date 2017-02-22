require 'spec_helper'

describe 'ingenerator-mysql::app_db_server' do
  let (:default_app_privileges) { sort }
  let (:node_environment)       { :localdev }
  let (:project_name)           { 'bookface' }
  let (:root_connection)        { { mocked_conn_details: 'are here' } }
  let (:db_attrs)               { {} }

  let (:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      db_attrs.each do |key, value|
        node.normal['project']['services']['db'][key] = value
      end
    end.converge described_recipe
  end

  before (:example) do
    allow_any_instance_of(Chef::Node).to receive(:mysql_root_connection).and_return(root_connection)
    allow_any_instance_of(Chef::Node).to receive(:ingenerator_project_name).and_return(project_name)
    allow_any_instance_of(Chef::Node).to receive(:node_environment).and_return(node_environment)
    allow_any_instance_of(Chef::Recipe).to receive(:node_environment).and_return(node_environment)
  end

  context 'by default' do
    it 'provisions an application_database for the default schema' do
      expect(chef_run).to create_application_database(project_name)
    end

    [:localdev, :buildslave].each do |env|
      context "in :#{env} environment" do
        let (:node_environment) { env }

        it 'allows the default mysql-appuser password' do
          expect { chef_run }.to_not raise_error
        end
      end
    end

    context 'in any other environment' do
      let (:node_environment) { :anything_productiony }

      context 'if the app user password is still default' do
        it 'throws an exception' do
          expect { chef_run }.to raise_exception Ingenerator::Helpers::Attributes::DefaultAttributeValueError
        end
      end

      context 'with customised app user password' do
        let (:db_attrs) { { 'password' => 'mysecurepassword' } }

        it 'does not throw' do
          expect { chef_run }.to_not raise_error
        end
      end
    end
  end

  context 'with custom schema name configuration' do
    let (:db_attrs) { { 'schema' => 'somedatabase' } }

    it 'creates the custom-named database' do
      expect(chef_run).to create_application_database('somedatabase')
    end
  end
end
