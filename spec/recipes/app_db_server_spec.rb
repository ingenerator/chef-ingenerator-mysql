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
    it 'creates a database named for the application using root connection' do
      expect(chef_run).to create_mysql_database(project_name).with(
        connection: root_connection
      )
    end

    it 'creates a database user named for the application using root connection' do
      expect(chef_run).to grant_mysql_database_user(project_name).with(
        connection: root_connection
      )
    end

    it 'only allows the app user to connect from localhost' do
      expect(chef_run).to grant_mysql_database_user(project_name).with(
        host: 'localhost'
      )
    end

    it 'grants user-level privileges on the application database to the application user' do
      expect(chef_run).to grant_mysql_database_user(project_name).with(
        database_name: project_name,
        privileges: ['DELETE', 'EXECUTE', 'INSERT', 'LOCK TABLES', 'SELECT', 'UPDATE']
      )
    end

    context 'in :localdev environment' do
      let (:node_environment) { :localdev }

      it 'sets the app user password to mysql-appuser' do
        expect(chef_run).to grant_mysql_database_user(project_name).with(
          password: 'mysql-appuser'
        )
      end
    end

    context 'in :buildslave environment' do
      let (:node_environment) { :buildslave }

      it 'sets the app user password to mysql-appuser' do
        expect(chef_run).to grant_mysql_database_user(project_name).with(
          password: 'mysql-appuser'
        )
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

        it 'assigns the custom root password' do
          expect(chef_run).to grant_mysql_database_user(project_name).with(
            password: 'mysecurepassword'
          )
        end
      end
    end
  end

  context 'with custom configuration' do
    context 'with connect_anywhere set' do
      let (:db_attrs)               { { 'connect_anywhere' => true } }

      it 'allows the app db user to connect from anywhere' do
        expect(chef_run).to grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
          host: '%'
        )
      end
    end

    context 'with custom schema and user names' do
      let (:db_attrs) do
        {
          'schema' => 'somedatabase',
          'user' => 'someuser'
        }
      end

      it 'creates the custom-named database' do
        expect(chef_run).to create_mysql_database('somedatabase')
      end

      it 'creates the custom-named user and grants access to custom schema' do
        expect(chef_run).to grant_mysql_database_user('someuser').with(
          database_name: 'somedatabase'
        )
      end
    end

    context 'with additional and disabled default privileges' do
      let (:db_attrs) do
        {
          privileges: { 'DROP' => true, 'DELETE' => false, 'UPDATE' => false }
        }
      end

      it 'only grants the expected privileges' do
        expect(chef_run).to grant_mysql_database_user(project_name).with(
          database_name: project_name,
          privileges: ['DROP', 'EXECUTE', 'INSERT', 'LOCK TABLES', 'SELECT']
        )
      end
    end
  end
end
