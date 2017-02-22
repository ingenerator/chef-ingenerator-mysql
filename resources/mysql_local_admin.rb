# mysql_local_admin creates a paired database user and local .my.cnf file
#
# By default, the user gets a secure random-generated password that will be
# persisted for the life of an instance in the node attributes, and a set of
# limited privileges (no truncate or schema altering permissions) that can still
# do damage, but not as much as dropping a table. They also get forced to use
# safe_updates mode.
#
# Use it like:
#
#   mysql_local_admin 'andrew' do
#     default_database 'app-schema' # optional
#   end
#

resource_name :mysql_local_admin

# This will be both the system user and database user
property :user, String, name_property: true, required: true

# If no password is provided, the node attributes are checked and failing that a
# password is generated and stored in node attributes for future reuse
property :password, String

# By default will be calculated as /home/#{user} - config file will go here
property :home_directory, String

# If specified the user will get this db by default
property :default_database, String

# Can be customised, specify [:all] for full privileges. Privileges apply across
# all databases and tables
property :privileges, Array, required: true, default: Ingenerator::Mysql::DEFAULT_ADMIN_PRIVS

default_action :create

action :create do
  mysql_database_user new_resource.user do
    action     [:create, :grant]
    connection node.mysql_root_connection()
    password   user_password
    host       '127.0.0.1'
    privileges new_resource.privileges
  end

  user_mysql_config config_file_path do
    user            new_resource.user
    connection      username: new_resource.user,
                    password: user_password,
                    host:     '127.0.0.1'
    database        new_resource.default_database if new_resource.default_database
    safe_updates    true
    default_charset 'utf8'
  end
end

action_class do
  # Retrieve or generate a password
  def user_password
    new_resource.password || stored_node_password || generate_password
  end

  # This will be a previously random-generated password to reuse
  def stored_node_password
    if node['mysql']['local_admins'] && node['mysql']['local_admins'][new_resource.user]
      node['mysql']['local_admins'][new_resource.user]['password']
    end
  end

  # Creates a secure password and stores on the node for reuse
  def generate_password
    require 'securerandom' unless defined?(SecureRandom)
    password = SecureRandom.hex(30)
    node.normal['mysql']['local_admins'][new_resource.user]['password'] = password
    password
  end

  def config_file_path
    if new_resource.home_directory
      ::File.join(new_resource.home_directory, '.my.cnf')
    else
      ::File.join('/home', new_resource.user, '.my.cnf')
    end
  end
end
