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

raise_unless_customised('mysql.server_root_password') if not_environment?(:localdev, :buildslave)

# Install and configure the mysql server
mysql_service 'default' do
  action                [:create, :start]
  bind_address          node['mysql']['bind_address']
  initial_root_password node['mysql']['server_root_password']
  socket                node['mysql']['default_server_socket']
end

# Install the mysql client libraries and chef gem to allow chef to provision
# users and databases - this has to come next to allow mysql_database_user
# and similar resources to work.
mysql_client_installation_package 'default'
mysql2_chef_gem 'default'

# Provision a root mysql client config file with credentials
# This has to come immediately after the service definition as it is used
# by the custom_config resource to load timezones
user_mysql_config '/root/.my.cnf' do
  connection      node.mysql_root_connection()
  default_charset 'utf8'
end

include_recipe 'ingenerator-mysql::custom_config'

# Fix logrotation for the default server
include_recipe 'ingenerator-mysql::fix_logrotate'

# Provision application databases and users if required
include_recipe 'ingenerator-mysql::app_db_server'
