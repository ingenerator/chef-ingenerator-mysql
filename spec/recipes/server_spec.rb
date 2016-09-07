require 'spec_helper'

describe 'ingenerator-mysql::server' do
  let (:mysql_attrs)       { {} }
  let (:node_environment)  { :localdev }
  let (:chef_run) do
    ChefSpec::SoloRunner.new do | node |
      node.normal['ingenerator']['node_environment'] = node_environment
      mysql_attrs.each do | key, value |
        node.normal['mysql'][key] = value
      end
    end.converge described_recipe
  end

  before do
    # stub guards used by the included recipes
    stub_command("\"/usr/bin/mysql\" -u root -e 'show databases;'").and_return(true)

    # mysql cookbook adds a *lot* of warnings to the log
    allow(Chef::Log).to receive(:warn)
  end

  context 'with invalid legacy configuration' do
    let (:chef_run) { ChefSpec::SoloRunner.new }

    %w(server_debian_password server_repl_password allow_remote_root remove_anonymous_users).each do | key |
      it "throws if a #{key} value is still defined in the mysql configuration" do
        chef_run.node.normal['mysql'][key] = 'anything'
        expect { chef_run.converge described_recipe }.to raise_error(ArgumentError)
      end
    end

  end

  context 'with default configuration' do

    it "creates the default mysql service" do
      expect(chef_run).to create_mysql_service 'default'
    end

    it "starts the default mysql service" do
      expect(chef_run).to start_mysql_service 'default'
    end

    it 'assigns the server socket path' do
      expect(chef_run).to create_mysql_service('default').with(
        :socket => chef_run.node['mysql']['default_server_socket']
      )
    end

    it 'binds to accept only localhost connections' do
      expect(chef_run).to create_mysql_service('default').with(
        :bind_address => '127.0.0.1'
      )
    end

    it 'uses the standard ubuntu distribution path for the mysql socket' do
      # For simple compatibility with mysql client software
      expect(chef_run.node['mysql']['default_server_socket']).to eq('/var/run/mysqld/mysqld.sock')
    end

    it "installs custom configuration" do
      expect(chef_run).to include_recipe "ingenerator-mysql::custom_config"
    end

    it 'installs and creates the mysql client with the dev package' do
      expect(chef_run).to install_mysql_client_installation_package 'default'
      # NB we probably shouldn't have to explicitly install this - this is a mysql cookbook bug
      # see https://github.com/chef-cookbooks/mysql/issues/457
      expect(chef_run).to install_package 'libmysqlclient-dev'
    end

    it "installs the mysql2_chef_gem to enable database cookbook providers" do
      expect(chef_run).to install_mysql2_chef_gem 'default'
    end

    it "manages the application database via the ingenerator-mysql::app_db_server recipe" do
      expect(chef_run).to include_recipe "ingenerator-mysql::app_db_server"
    end

    context 'in :localdev environment' do
      let (:node_environment) { :localdev }

      it 'assigns the initial root password as `mysql`' do
        expect(chef_run).to create_mysql_service('default').with(
          :initial_root_password => 'mysql'
        )
      end
    end

    context 'in :buildslave environment' do
      let (:node_environment) { :buildslave }

      it 'assigns the initial root password as `mysql`' do
        expect(chef_run).to create_mysql_service('default').with(
          :initial_root_password => 'mysql'
        )
      end
    end

    context 'in any other environment' do
      let (:node_environment) { :'anything_productiony' }

      context 'if root password is still default' do
        it 'throws exception' do
          expect {
            chef_run
          }.to raise_exception(ArgumentError)
        end
      end

      context 'with customised root password' do
        let (:mysql_attrs) { {'server_root_password' => 'mysecurepassword'}}

        it 'assigns the custom root password' do
          expect(chef_run).to create_mysql_service('default').with(
            :initial_root_password => 'mysecurepassword'
          )
        end
      end
    end
  end

  context 'with custom configuration' do
    let (:mysql_attrs) do
      {
        'server_root_password'  => 'foobar',
        'bind_address'          => '0.0.0.0',
        'default_server_socket' => '/var/mysql.sock'
      }
    end

    it 'assigns custom parameters to mysql service' do
      expect(chef_run).to create_mysql_service('default').with(
        :initial_root_password => 'foobar',
        :bind_address          => '0.0.0.0',
        :socket                => '/var/mysql.sock'
      )
    end
  end
end
