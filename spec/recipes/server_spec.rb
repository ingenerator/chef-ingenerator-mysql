require 'spec_helper'

describe 'ingenerator-mysql::server' do
  let (:mysql_attrs)       { {} }
  let (:node_environment)  { :localdev }
  let (:root_connection)   { { username: 'rooty', password: 'whatever', host: '127.0.0.1' } }
  let (:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      mysql_attrs.each do |key, value|
        node.normal['mysql'][key] = value
      end
      node.normal['project']['services']['db']['password'] = 'custompass'
    end.converge described_recipe
  end

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
  end

  context 'with default configuration' do
    it 'creates the default mysql service' do
      expect(chef_run).to create_mysql_service 'default'
    end

    it 'starts the default mysql service' do
      expect(chef_run).to start_mysql_service 'default'
    end

    it 'assigns the server socket path' do
      expect(chef_run).to create_mysql_service('default').with(
        socket: chef_run.node['mysql']['default_server_socket']
      )
    end

    it 'binds to accept only localhost connections' do
      expect(chef_run).to create_mysql_service('default').with(
        bind_address: '127.0.0.1'
      )
    end

    it 'uses the standard ubuntu distribution path for the mysql socket' do
      # For simple compatibility with mysql client software
      expect(chef_run.node['mysql']['default_server_socket']).to eq('/var/run/mysqld/mysqld.sock')
    end

    it 'installs custom configuration' do
      expect(chef_run).to include_recipe 'ingenerator-mysql::custom_config'
    end

    it 'installs the mysql2_chef_gem to enable database cookbook providers' do
      expect(chef_run).to install_mysql2_chef_gem 'default'
    end

    it 'manages the application database via the ingenerator-mysql::app_db_server recipe' do
      expect(chef_run).to include_recipe 'ingenerator-mysql::app_db_server'
    end

    it 'fixed mysql logrotation via the ingenerator-mysql::fix_logrotate recipe' do
      expect(chef_run).to include_recipe 'ingenerator-mysql::fix_logrotate'
    end

    it 'provisions a mysql user config at /root/.my.cnf with the root credentials' do
      expect(chef_run).to create_user_mysql_config('/root/.my.cnf').with(
        user:            'root',
        mode:            0o600,
        connection:      root_connection,
        safe_updates:    false,
        default_charset: 'utf8'
      )
    end

    context 'in :localdev environment' do
      let (:node_environment) { :localdev }

      it 'assigns the initial root password as `mysql`' do
        expect(chef_run).to create_mysql_service('default').with(
          initial_root_password: 'mysql'
        )
      end
    end

    context 'in :buildslave environment' do
      let (:node_environment) { :buildslave }

      it 'assigns the initial root password as `mysql`' do
        expect(chef_run).to create_mysql_service('default').with(
          initial_root_password: 'mysql'
        )
      end
    end

    context 'in any other environment' do
      let (:node_environment) { :anything_productiony }

      context 'if root password is still default' do
        it 'throws exception' do
          expect do
            chef_run
          end.to raise_exception(Ingenerator::Helpers::Attributes::DefaultAttributeValueError)
        end
      end

      context 'with customised root password' do
        let (:mysql_attrs) { { 'server_root_password' => 'mysecurepassword' } }

        it 'assigns the custom root password' do
          expect(chef_run).to create_mysql_service('default').with(
            initial_root_password: 'mysecurepassword'
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
        initial_root_password: 'foobar',
        bind_address: '0.0.0.0',
        socket: '/var/mysql.sock'
      )
    end
  end
end
