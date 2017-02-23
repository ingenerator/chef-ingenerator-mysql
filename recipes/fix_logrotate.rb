#
# Fixes the logrotate config for the default mysql server
#
# This relates to https://github.com/chef-cookbooks/mysql/issues/294 - basically,
# because the chef mysql cookbook now supports multiple instances on one box they
# do all sorts of mucking about with the default package, but they don't do
# anything to fix the default /etc/logrotate/mysql-server script, so that will
# fail because it's looking for a creds file and config that don't exist.

# https://github.com/flatrocks/cookbook-mysql_logrotate provides a decent
# resolution for this that supports multi-server, but that's overly complex
# since we only support running a single `mysql-default` on a box.
#
# This approcah is inspired by what @flatrocks did, but more hardcoded and
# without adding a logrotate cookbook dependency

# This user can only issue a flush logs command, and only from localhost. It's
# the password doesn't really need to be secure since if someone can execute
# commands on localhost we've bigger problems than log flushing.
rotate_user     = 'logrotate'
rotate_password = 'logrotate'

mysql_database_user rotate_user do
  action     :grant
  connection node.mysql_root_connection()
  password   rotate_password
  privileges %w(USAGE RELOAD)
end

template '/etc/logrotate.d/mysql-server' do
  source 'logrotate-mysql-server.erb'
  mode   0o644
  variables(
    user:     rotate_user,
    password: rotate_password,
    socket:   node['mysql']['default_server_socket'],
    log_files: [
      '/var/log/mysql.log',
      '/var/log/mysql-default/mysql.log',
      '/var/log/mysql-default/mysql-slow.log',
      '/var/log/mysql-default/error.log'
    ]
  )
end
