#
# Installs the database schema and user required for the application itself
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Recipe:: app_db_server
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

app_db_attributes = node['project']['services']['db']

# Security check for using default passwords outside vagrant
raise_unless_customised('project.services.db.password') if not_environment?(:localdev, :buildslave)

# Create the application database
mysql_database app_db_attributes['schema'] do
  action      :create
  connection  node.mysql_root_connection()
end

# Create the standard application database user with the configured privileges
mysql_database_user app_db_attributes['user'] do
  action        :grant
  connection    node.mysql_root_connection()
  database_name app_db_attributes['schema']
  host          app_db_attributes['connect_anywhere'] ? '%' : 'localhost'
  password      app_db_attributes['password']
  privileges    app_db_attributes['privileges'].list_active_keys
end
