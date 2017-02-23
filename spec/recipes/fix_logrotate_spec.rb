require 'spec_helper'

describe 'ingenerator-mysql::fix_logrotate' do
  let (:root_connection) { { mocked_conn_details: 'are here' } }
  let (:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['mysql']['default_server_socket'] = '/var/run/some.sock'
    end.converge described_recipe
  end

  before (:example) do
    allow_any_instance_of(Chef::Node).to receive(:mysql_root_connection).and_return(root_connection)
  end

  it 'creates a logrotate db user with rotatelogs permissions' do
    expect(chef_run).to grant_mysql_database_user('logrotate').with(
      connection: root_connection,
      host: 'localhost',
      privileges: %w(USAGE RELOAD),
      password: 'logrotate'
    )
  end

  it 'replaces the default mysql logrotate script' do
    expect_logs = Regexp.quote('/var/log/mysql-default/error.log /var/log/mysql-default/mysql-slow.log /var/log/mysql-default/mysql.log /var/log/mysql.log {')
    expect_cmd  = Regexp.quote('CMD="/usr/bin/mysqladmin -ulogrotate -plogrotate --socket=/var/run/some.sock flush-logs"')

    expect(chef_run).to render_file('/etc/logrotate.d/mysql-server')
      .with_content(Regexp.new("\n" + expect_logs + "\n"))
      .with_content(Regexp.new("\n" + '\s+' + expect_cmd + "\n"))
  end
end
