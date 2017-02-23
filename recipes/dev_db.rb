#
# Provisions a standard development environment database based on SQL files within the repo
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Recipe:: dev_db
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

# Protect against running on a live instance
root_connection = node.mysql_root_connection()
unless root_connection[:password] == 'mysql'
  raise "It looks unsafe to run the ingenerator-mysql::dev_db recipe on this database server\n"\
        "The root password has been changed from mysql, which suggests this might not be a \n"\
        "development or test server. This recipe would wipe your db and replace it with test\n"\
        'data. I just stopped you getting fired'
end

local_schema_path = node['mysql']['dev_db']['schema_path']
recreate_always   = node['mysql']['dev_db']['recreate_always']

node['mysql']['dev_db']['sql_files'].list_active_keys.each do |cook_file|
  cookbook_name, relative_file = cook_file.split('::')
  local_path    = File.join(local_schema_path, relative_file)
  mysql_command = "cat #{local_path} | mysql -uroot -p#{root_connection[:password]}"

  # Ensure the local directory exists
  directory File.dirname(local_path) do
    action    :create
    recursive true
    mode      0o755
  end

  # Provision the SQL file locally
  cookbook_file local_path do
    cookbook cookbook_name
    source   relative_file
    unless recreate_always
      notifies :run, 'execute[' + mysql_command + ']', :immediately
    end
  end

  # Read the SQL file into mysql
  execute mysql_command do
    action recreate_always ? :run : :nothing
  end
end
