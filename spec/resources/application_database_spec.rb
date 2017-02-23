require 'spec_helper'

describe_resource 'resources::application_database' do
  let (:resource)        { 'application_database' }
  let (:root_connection) { { mocked_conn_details: 'are here' } }
  let (:test_schema)     { 'peoples'   }
  let (:project_name)    { 'myproject' }

  let (:mysql_query_out) { "*************************** 1. row ***************************\nCOUNT(*): 0\n" }
  let (:mysql_cmd)       { 'mysql --defaults-extra-file=/root/.my.cnf --vertical -e"SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=\'' + test_schema + '\'"' }
  let (:seed_exists?)    { false }
  let (:seed_file)       { '/tmp/database-seeds/' + test_schema + '.sql' }

  let (:node_attributes) do
    { test: { schema: test_schema } }
  end

  before(:each) do
    allow_any_instance_of(Chef::Node).to receive(:mysql_root_connection).and_return(root_connection)
    allow_any_instance_of(Chef::Node).to receive(:ingenerator_project_name).and_return(project_name)

    mysql_shellout_result = double('shellout').as_null_object
    allow(Mixlib::ShellOut).to receive(:new).with(mysql_cmd, any_args).and_return(mysql_shellout_result)
    allow(mysql_shellout_result).to receive(:stdout).and_return(mysql_query_out)

    # Need to allow File.exist? to work normally and only skip for this one
    allow(File).to receive(:exist?).with(anything).and_call_original
    allow(File).to receive(:exist?).with(seed_file).and_return(seed_exists?)

    # Suppress actually outputting the warnings about not seeding a database
    allow(Chef::Log).to receive(:warn).with(anything).and_call_original
    allow(Chef::Log).to receive(:warn).with(/Database \w+ is empty/)
  end

  describe 'create' do
    context 'with default configuration' do
      it 'creates a database schema with the root connection details' do
        expect(chef_run).to create_mysql_database('peoples').with(
          connection: root_connection
        )
      end

      context 'when mysql produces unexpected output format' do
        let (:mysql_query_out) { "*************************** 1. row ***************************\njunkety: 15\n" }

        it 'raises an exception' do
          expect { chef_run }.to raise_error(RuntimeError, /Unexpected query result/)
        end
      end

      context 'when the database is empty' do
        let (:mysql_query_out) { "*************************** 1. row ***************************\nCOUNT(*): 0\n" }

        context 'when a seed file exists' do
          let (:seed_exists?) { true }
          it 'populates the database from the seed and deletes it' do
            expect(chef_run).to run_execute('seed peoples database').with(
              command: 'cat /tmp/database-seeds/peoples.sql | mysql --defaults-extra-file=/root/.my.cnf --database=peoples && rm /tmp/database-seeds/peoples.sql'
            )
          end
        end

        context 'when no seed file exists' do
          let (:seed_exists?) { false }

          it 'logs a warning' do
            expect(Chef::Log).to receive(:warn).with('Database peoples is empty but no seed file was provided at /tmp/database-seeds/peoples.sql')
            chef_run
          end
        end
      end

      context 'when the database is not empty' do
        let (:mysql_query_out) { "*************************** 1. row ***************************\nCOUNT(*): 23\n" }

        context 'when a seed file exists' do
          let (:seed_exists?) { true }
          it 'throws an exception' do
            expect { chef_run }.to raise_error(RuntimeError, /Cannot seed a non-empty database/)
          end
        end

        context 'when no seed file exists' do
          let (:seed_exists?) { false }
          it 'does nothing' do
            expect { chef_run }.to_not raise_error
          end
        end
      end

      it 'grants the application user basic database privileges from localhost' do
        expect(chef_run).to grant_mysql_database_user('myproject').with(
          connection: root_connection,
          database_name:   'peoples',
          host:            'localhost',
          password:      'mysql-appuser',
          privileges: ['DELETE', 'EXECUTE', 'INSERT', 'LOCK TABLES', 'SELECT', 'UPDATE']
        )
      end
    end

    context 'when default node attributes are customised' do
      it 'grants the application user access from anywhere when connect_anywhere is set' do
        chef_runner.node.normal['project']['services']['db']['connect_anywhere'] = true
        expect(chef_run).to grant_mysql_database_user('myproject').with(
          host: '%'
        )
      end

      it 'grants the application user additional privileges when enabled' do
        chef_runner.node.normal['project']['services']['db']['privileges']['DROP'] = true
        expect(chef_run).to grant_mysql_database_user('myproject').with(
          privileges: ['DELETE', 'DROP', 'EXECUTE', 'INSERT', 'LOCK TABLES', 'SELECT', 'UPDATE']
        )
      end

      it 'does not grant the application user disabled privileges' do
        chef_runner.node.normal['project']['services']['db']['privileges']['SELECT'] = false
        expect(chef_run).to grant_mysql_database_user('myproject').with(
          privileges: ['DELETE', 'EXECUTE', 'INSERT', 'LOCK TABLES', 'UPDATE']
        )
      end

      it 'specifies a customised username for the application user' do
        chef_runner.node.normal['project']['services']['db']['user'] = 'jonthn'
        expect(chef_run).to grant_mysql_database_user('jonthn')
      end
      it 'specifies a customised password for the application user' do
        chef_runner.node.normal['project']['services']['db']['password'] = 'secured'
        expect(chef_run).to grant_mysql_database_user('myproject').with(
          password: 'secured'
        )
      end
    end
  end
end
