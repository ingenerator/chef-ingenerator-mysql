# Provisions and optionally one-time seeds an application database, and grants
# user-level permissions to the application user that will access it.
#
# To seed a database, drop a sql file in /tmp/database-seeds/{schema-name}.sql
# - this will be piped into the newly created database then deleted. If there
# are already any tables of views in the selected schema, a RuntimeError will be
# thrown.
#
# Currently all the options for this resource are controlled by node attributes,
# I plan in future to allow per-resource overriding of the defaults.

resource_name :application_database

# The name of the schema to create, seed and grant rights on
property :schema, String, name_property: true, required: true

default_action :create

action :create do
  mysql_database new_resource.schema do
    connection node.mysql_root_connection()
  end

  mysql_database_user app_db_username do
    action        :grant
    connection    node.mysql_root_connection()
    username      app_db_attributes['user']
    database_name new_resource.schema
    host          app_db_attributes['connect_anywhere'] ? '%' : 'localhost'
    password      app_db_attributes['password']
    privileges    app_db_attributes['privileges'].list_active_keys
  end

  # Use direct logic rather than guards to allow for our exception and warning
  # cases.
  if ::File.exist?(seed_file_path)
    raise 'Cannot seed a non-empty database' unless schema_empty?

    execute 'seed ' + new_resource.schema + ' database' do
      command seed_database_command
    end
  else
    warn_not_seeded if schema_empty?
  end
end

action_class do

  def app_db_attributes
    node['project']['services']['db']
  end

  def app_db_username
    app_db_attributes['user']
  end

  # Check if the resource schema has any tables or views
  def schema_empty?
    cmd = mysql_client_cmd + ' --vertical -e"SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=\'' + new_resource.schema + '\'"'
    output = shell_out!(cmd).stdout
    matches = /^COUNT\(\*\):\s+([0-9]+)$/m.match(output)
    raise "Unexpected query result: \n" + output unless matches
    matches[1] == '0'
  end

  def seed_file_path
    "/tmp/database-seeds/#{new_resource.schema}.sql"
  end

  def seed_database_command
    "cat #{seed_file_path} | #{mysql_client_cmd} --database=#{new_resource.schema} && rm #{seed_file_path}"
  end

  def mysql_client_cmd
    'mysql --defaults-extra-file=/root/.my.cnf'
  end

  def warn_not_seeded
    Chef::Log.warn(
      format(
        'Database %s is empty but no seed file was provided at %s',
        new_resource.schema,
        seed_file_path
      )
    )
  end
end
