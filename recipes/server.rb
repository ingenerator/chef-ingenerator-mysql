#
# Installs the database server for the application
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Recipe:: server
#
# Copyright 2012-13, inGenerator Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

raise_if_legacy_attributes(
  'mysql.server_debian_password',
  'mysql.server_repl_password',
  'mysql.allow_remote_root',
  'mysql.remove_anonymous_users'
)

if '/var/run/mysqld/mysqld.sock' != node['mysql']['default_server_socket']
  raise ArgumentError.new("You MUST NOT attempt to customise node['mysql']['default_server_socket']. Leave it alone!")
end

# Install all packages plus the ruby client gem for mysql
package 'mysql-server-5.7'
package 'mysql-client-5.7'
package 'libmysqlclient-dev'
gem_package 'mysql2' do
  gem_binary RbConfig::CONFIG['bindir'] + '/gem'
  version    '0.5.2'
  action     :install
end

# Initialise the mysql server if required
mysql_server_init 'init mysql' do
  action [:secure_db, :import_timezones]
end

# Configure custom config
include_recipe 'ingenerator-mysql::custom_config'

# Fix logrotation for the default server
include_recipe 'ingenerator-mysql::fix_logrotate'

# Provision application databases and users if required
include_recipe 'ingenerator-mysql::app_db_server'
