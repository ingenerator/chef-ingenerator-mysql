require 'spec_helper'

describe_resource 'resources::mysql_local_admin' do
  let (:resource) { 'mysql_local_admin' }
  let (:root_connection) { { mocked_conn_details: 'are here' } }
  let (:test_user) { 'jimmy' }
  let (:test_password) { nil }
  let (:test_homedir) { nil }
  let (:test_db) { nil }
  let (:test_privileges) { nil }

  let (:node_attributes) do
    { test: { user: test_user, password: test_password, homedir: test_homedir, db: test_db, privileges: test_privileges } }
  end

  before(:each) do
    allow_any_instance_of(Chef::Node).to receive(:mysql_root_connection).and_return(root_connection)
  end

  describe 'configure' do
    shared_examples 'provisions a database user and config file' do |expected|
      it 'provisions a local database user with the expected password' do
        expect(chef_run).to create_mysql_database_user(expected[:user]).with(
          password: expected[:password],
          host:     '127.0.0.1',
          connection: root_connection
        )
      end

      it 'provisions a user_mysql_config with the expected credentials' do
        expect(chef_run).to create_user_mysql_config('/home/' + expected[:user] + '/.my.cnf').with(
          user: expected[:user],
          connection: { username: expected[:user], password: expected[:password], host: '127.0.0.1' }
        )
      end
    end

    context 'by default with stubbed random password' do
      let (:expect_password) { 'randompassword' }
      before(:each) do
        allow(SecureRandom).to receive(:hex).with(30).and_return('randompassword')
      end

      it 'creates a random password and stores in node attributes' do
        expect(normal_attributes(chef_run.node, 'mysql.local_admins')).to eq(
          'jimmy' => { 'password' => 'randompassword' }
        )
      end

      include_examples 'provisions a database user and config file', user: 'jimmy', password: 'randompassword'

      it 'grants the database user limited permissions on all schemas' do
        expect(chef_run).to grant_mysql_database_user('jimmy').with(
          database_name: nil,
          table: nil,
          privileges: Ingenerator::Mysql::DEFAULT_ADMIN_PRIVS
        )
      end

      it 'configures the user to connect with safe-updates mode active' do
        expect(chef_run).to create_user_mysql_config('/home/jimmy/.my.cnf').with(
          safe_updates: true
        )
      end

      it 'configures the user to connect with a utf8 default character set' do
        expect(chef_run).to create_user_mysql_config('/home/jimmy/.my.cnf').with(
          default_charset: 'utf8'
        )
      end
    end

    context 'by default with real random password' do
      let (:test_user) { 'john' }

      it 'successfully creates a random password' do
        expect(normal_attributes(chef_run.node, 'mysql.local_admins.john.password')).to match(/^[a-f0-9]{60}$/)
      end
    end

    context 'when a password exists in node attributes' do
      before(:each) do
        chef_runner.node.normal['mysql']['local_admins']['jimmy']['password'] = 'bears'
      end

      it 'does not regenerate the password' do
        expect(normal_attributes(chef_run.node, 'mysql.local_admins')).to eq(
          'jimmy' => { 'password' => 'bears' }
        )
      end

      include_examples 'provisions a database user and config file', user: 'jimmy', password: 'bears'
    end

    context 'when a password is specified for the resource' do
      let (:test_password) { 'franklin' }

      it 'does not populate a password in node attributes' do
        expect(normal_attributes(chef_run.node, 'mysql.local_admins')).to be(:not_present)
      end

      include_examples 'provisions a database user and config file', user: 'jimmy', password: 'franklin'
    end

    context 'when a home directory is specified' do
      let (:test_homedir) { '/my/home' }
      let (:test_user) { 'peter' }

      it 'provisions config file in that home directory' do
        expect(chef_run).to create_user_mysql_config('/my/home/.my.cnf').with(
          user: 'peter'
        )
      end
    end

    context 'when a default database is specified' do
      let (:test_db) { 'a-schema' }

      it 'provisions the default database in the user config file' do
        expect(chef_run).to create_user_mysql_config('/home/jimmy/.my.cnf').with(
          database: 'a-schema'
        )
      end
    end

    context 'when privileges are specified' do
      let (:test_privileges) { ['DROP'] }

      it 'grants only the specified privileges' do
        expect(chef_run).to grant_mysql_database_user('jimmy').with(
          privileges: ['DROP']
        )
      end
    end

    def normal_attributes(node, attr_path)
      attr_keys = attr_path.split('.')
      node.debug_value(*attr_keys).to_h['normal']
    end
  end
end
