#
# Helpers for the cookbook
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
#
module Ingenerator
  module Mysql
    # Assigned as the default privileges for a mysql_local_admin
    # The ||= is to prevent warnings when chefspec reloads the helper in each run
    DEFAULT_ADMIN_PRIVS ||= [
      'CREATE TEMPORARY TABLES',
      'DELETE',
      'EXECUTE',
      'FILE',
      'INSERT',
      'LOCK TABLES',
      'PROCESS',
      'SELECT',
      'SHOW DATABASES',
      'SHOW VIEW',
      'UPDATE',
      'USAGE'
    ].freeze

    module Helpers
      # Gets the current root account connection details as a hash
      def mysql_root_connection
        unless node['mysql'] && node['mysql']['server_root_password']
          raise ArgumentError, 'No root password defined in node.mysql.server_root_password'
        end

        {
          host: '127.0.0.1',
          username: 'root',
          password: node['mysql']['server_root_password']
        }
      end
    end
  end
end

# Make the helpers available in all recipes
Chef::Node.send(:include, Ingenerator::Mysql::Helpers)
