# user_mysql_config provisions a mysql client config file with credentials
# to access the mysql instance.
#
#   user_mysql_config '/home/me/.my.cnf' do
#     user            'me'
#     connection      node.mysql_root_connection()
#     safe_updates    true
#     default_charset 'UTF-8'
#   end
#
resource_name :user_mysql_config

# Path to the file to create
property :path, String, name_property: true

# User to own the file
property :user, String, default: 'root', required: true

# Permissions mask for the file
property :mode, Integer, default: 0o600, required: true

# Server connection details
property :connection, Hash, required: true, callbacks: {
  'connection.password is required' => ->(val) { val[:password] },
  'connection.username is required' => ->(val) { val[:username] },
  'connection.host is required' => ->(val) { val[:host] }
}

# Default database to use
property :database, String

# Whether to enforce safe-updates (require a primary key for any update or delete)
property :safe_updates, [TrueClass, FalseClass], default: false

# Init the connection to this charset
property :default_charset, String

default_action :create

action :create do
  file new_resource.path do
    user      new_resource.user
    mode      new_resource.mode
    content   config_file_content
    sensitive true
  end
end

# Helper methods
action_class do
  def config_file_content
    cfg = "# Provisioned by chef - do not edit locally\n"
    cfg << "[client]\n"
    cfg << config_line('user', new_resource.connection[:username])
    cfg << config_line('password', new_resource.connection[:password])
    cfg << config_line('host', new_resource.connection[:host])
    cfg << config_line('database', new_resource.database) if new_resource.database
    cfg << config_line('safe-updates', 1) if new_resource.safe_updates
    cfg << config_line('default-character-set', new_resource.default_charset) if new_resource.default_charset
    cfg
  end

  def config_line(key, value)
    if value.is_a? String
      escaped = "'" + value.gsub('\\') { '\\\\' }.gsub("'") { '\\\'' } + "'"
    else
      escaped = value
    end

    format("%s=%s\n", key, escaped)
  end
end
