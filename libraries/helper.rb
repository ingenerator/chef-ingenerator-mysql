#
# Helpers for the cookbook
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
#
module Ingenerator
  module Mysql
    module Helpers

      # Gets the current root account connection details as a hash
      def mysql_root_connection
        unless node['mysql'] && node['mysql']['server_root_password']
          raise ArgumentError.new('No root password defined in node.mysql.server_root_password')
        end

        {
          :host     => '127.0.0.1',
          :username => 'root',
          :password => node['mysql']['server_root_password'],
        }
      end
    end
  end
end

# Make the helpers available in all recipes
Chef::Node.send(:include, Ingenerator::Mysql::Helpers)
