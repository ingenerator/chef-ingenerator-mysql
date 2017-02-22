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
raise_if_legacy_attributes(
  'mysql.tunable',
  'mysql.custom_config.bind_address',
  'mysql.custom_config.default-time-zone'
)

# Ensure the mysql_service resource is defined for notification
find_resource(:mysql_service, 'default') do
  action :nothing
end

# Options must be sorted in order, as Ruby doesn't guarantee hash order by default and so can cause
# unexpected file changes
options = []
if node['mysql']['custom_config']
  node['mysql']['custom_config'].sort.each do |key, value|
    options << { key: key, value: value } unless value.nil?
  end
end

mysql_config 'custom' do
  instance 'default'
  source   'custom.cnf.erb'
  variables(
    options: options
  )
end

# Configure the database timezone
mysql_default_timezone node['mysql']['default-time-zone'] do
  notifies :restart, 'mysql_service[default]', :immediately
end
