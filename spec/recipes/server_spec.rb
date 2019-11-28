require 'spec_helper'

describe 'ingenerator-mysql::server' do
  let (:mysql_attrs)       { {} }
  let (:node_environment)  { :localdev }
  let (:root_connection)   { { username: 'rooty', password: 'whatever', host: '127.0.0.1' } }
  let (:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      mysql_attrs.each do |key, value|
        node.normal['mysql'][key] = value
      end
      node.normal['project']['services']['db']['password'] = 'custompass'
    end
  end
  let (:chef_run) { chef_runner.converge described_recipe }

  before (:example) do
    allow_any_instance_of(Chef::Node).to receive(:mysql_root_connection).and_return(root_connection)
    allow_any_instance_of(Chef::Node).to receive(:node_environment).and_return(node_environment)
    allow_any_instance_of(Chef::Recipe).to receive(:node_environment).and_return(node_environment)
  end

  context 'with invalid legacy configuration' do
    let (:chef_run) { ChefSpec::SoloRunner.new }

    %w(server_debian_password server_repl_password allow_remote_root remove_anonymous_users).each do |key|
      it "throws if a #{key} value is still defined in the mysql configuration" do
        chef_run.node.normal['mysql'][key] = 'anything'
        expect { chef_run.converge described_recipe }.to raise_error(Ingenerator::Helpers::Attributes::LegacyAttributeDefinitionError)
      end
    end

    it 'throws if some fool tries to change the socket path' do
      chef_run.node.normal['mysql']['default_server_socket'] = '/foo/bar'
      expect { chef_run.converge described_recipe }.to raise_error /MUST NOT attempt to customise node\['mysql'\]\['default_server_socket'\]/
    end

    it 'throws if some fool tries to change the data directory' do
      chef_run.node.normal['mysql']['data_dir'] = '/foo/bar'
      expect { chef_run.converge described_recipe }.to raise_error /MUST NOT attempt to customise node\['mysql'\]\['data_dir'\]/
    end
  end

  context 'with default configuration' do
    %w(mysql-server-5.7 mysql-client-5.7 libmysqlclient-dev).each do | pkg |
      it "installs the #{pkg} package" do
        expect(chef_run).to install_package pkg
      end
    end

    it 'installs the mysql2 gem' do
      #expect(chef_run).to install_gem_package 'mysql2'
    end

    it 'uses the standard ubuntu distribution path for the mysql socket' do
      # For simple compatibility with mysql client software
      expect(chef_run.node['mysql']['default_server_socket']).to eq('/var/run/mysqld/mysqld.sock')
    end

    it 'installs custom configuration' do
      expect(chef_run).to include_recipe 'ingenerator-mysql::custom_config'
    end

    it 'manages the application database via the ingenerator-mysql::app_db_server recipe' do
      expect(chef_run).to include_recipe 'ingenerator-mysql::app_db_server'
    end

    it 'fixed mysql logrotation via the ingenerator-mysql::fix_logrotate recipe' do
      expect(chef_run).to include_recipe 'ingenerator-mysql::fix_logrotate'
    end

    it 'defines the default mysql data_dir for other things to reference' do
      expect(chef_run.node['mysql']['data_dir']).to eq('/var/lib/mysql')
    end

  end

end
