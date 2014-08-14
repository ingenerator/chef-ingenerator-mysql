#
# Provisions custom mysql server configuration
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Recipe:: custom_config
#
# Copyright 2014, inGenerator Ltd
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

if node['mysql']['tunable']
  keys = node['mysql']['tunable'].keys.join(", ")
  raise ArgumentError, "node['mysql']['tunable'] is no longer supported - migrate the keys #{keys} to node['mysql]['custom_config']"
end

# Define the service for notification
service 'mysql'

template "/etc/mysql/conf.d/custom.cnf" do
  mode  0600
  owner 'mysql'
  group 'mysql'
  variables(
    :options => node['mysql']['custom_config']
  )
  notifies :restart, 'service[mysql]'
end