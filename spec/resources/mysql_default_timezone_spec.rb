require 'spec_helper'

describe_resource 'resources::mysql_default_timezone' do
  let (:resource) { 'mysql_default_timezone' }

  let (:node_attributes) do
    { test: { timezone: 'Europe/Paris' } }
  end

  describe 'configure' do
    context 'with default options' do
      let (:'is_tzs_empty?') { true }
      before(:each) do
        stub_command("mysql --defaults-extra-file=/root/.my.cnf --database=mysql -e'SELECT COUNT(*) AS tzs FROM mysql.time_zone \\G' | grep 'tzs: 0'").and_return(is_tzs_empty?)
      end

      context 'when mysql timezone info is not populated' do
        let (:'is_tzs_empty?') { true }
        it 'generates and imports it from zoneinfo' do
          expect(chef_run).to run_execute('populate mysql timezones').with(
            command: 'mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --defaults-extra-file=/root/.my.cnf --database=mysql'
          )
        end
      end

      context 'when mysql timezone info is already populated' do
        let (:'is_tzs_empty?') { false }
        it 'does not recreate it' do
          expect(chef_run).not_to run_execute('populate mysql timezones')
        end
      end

      it 'provisions a mysql config file with the timezone setting' do
        expect(chef_run).to create_mysql_config('default-time-zone').with(
          source:  'custom.cnf.erb',
          variables: { options: [{ key: 'default-time-zone', value: 'Europe/Paris' }] },
          instance: 'default'
        )
      end
    end

    context 'with custom credentials file option' do
      let (:node_attributes) do
        { test: { timezone: 'Europe/Paris', credential_file: '/some/con.fig' } }
      end

      it 'uses the custom credentials for the guard and the tz import' do
        stub_command("mysql --defaults-extra-file=/some/con.fig --database=mysql -e'SELECT COUNT(*) AS tzs FROM mysql.time_zone \\G' | grep 'tzs: 0'").and_return(true)
        expect(chef_run).to run_execute('populate mysql timezones').with(
          command: 'mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --defaults-extra-file=/some/con.fig --database=mysql'
        )
      end
    end
  end
end
