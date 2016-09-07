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

invalid_configs = []
%w(server_debian_password server_repl_password allow_remote_root remove_anonymous_users).each do | key |
  if node['mysql'].attribute?(key)
    invalid_configs << key
  end
end

unless invalid_configs.empty?
  raise ArgumentError.new(
    "Your environment defines legacy mysql config options that are no longer valid:\n"+invalid_configs.join(', ')
  )
end

mysql_service 'default' do
  action                [:create, :start]
  bind_address          node['mysql']['bind_address']
  initial_root_password node['mysql']['server_root_password']
end

include_recipe "ingenerator-mysql::custom_config"

# Install the chef gem to allow chef to provision users and databases
mysql2_chef_gem 'default' do
  action :install
end
include_recipe "ingenerator-mysql::root_user"
include_recipe "ingenerator-mysql::app_db_server"
