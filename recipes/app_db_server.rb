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
if node['vagrant'].nil?
  if (app_db_attributes['pasword'] == node['project']['name'])
    Chef::Log.warn('Your app db password is not secure and you are not running under vagrant - check your configuration')
  end
end

# Create the application database
mysql_database app_db_attributes['schema'] do
  action      :create
  connection  Chef::Recipe::IngeneratorMysqlHelper.root_connection(node)
end

# Create the standard application database user with the configured privileges
allow_privileges = []
app_db_attributes['privileges'].each do |privilege, should_grant|
  allow_privileges << privilege if should_grant
end
allow_privileges.sort

mysql_database_user app_db_attributes['user'] do
  action        :grant
  connection    Chef::Recipe::IngeneratorMysqlHelper.root_connection(node)
  database_name app_db_attributes['schema']
  host          app_db_attributes['connect_anywhere'] ? '%' : 'localhost'
  password      app_db_attributes['password']
  privileges    allow_privileges.sort
end

