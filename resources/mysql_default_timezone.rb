# Popuplates the mysql timezone info from /usr/share/zoneinfo and configures a
# default server timezone.
#
# [!!] NOTE: this does not do anything to set up future updates of the timezones
# - if that's likely to be an issue you will need to separately schedule and/or
# manually handle updating the timezone data.
#
# Use it like:
#
#   mysql_default_timezone 'Europe/London' do
#     notifies :restart, 'mysql_service[default]', :immediately
#   end
#
resource_name :mysql_default_timezone

# The timezone to set as server TZ
property :timezone, String, name_property: true

# The mysql credentials file to use for access to the DB - must exist
property :credential_file, String, required: true, default: '/root/.my.cnf'

default_action :configure

action :configure do
  execute 'populate mysql timezones' do
    command "mysql_tzinfo_to_sql /usr/share/zoneinfo | #{mysql_client_cmd}"
    only_if "#{mysql_client_cmd} -e'SELECT COUNT(*) AS tzs FROM mysql.time_zone \\G' | grep 'tzs: 0'"
  end

  mysql_config 'default-time-zone' do
    source     'custom.cnf.erb'
    variables  options: [{ key: 'default-time-zone', value: new_resource.timezone }]
  end
end

action_class do
  def mysql_client_cmd
    "mysql --defaults-extra-file=#{new_resource.credential_file} --database=mysql"
  end
end
