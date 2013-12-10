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

# Security check for using default passwords outside vagrant
if node['vagrant'].nil?
  if (node['mysql']['server_root_password'] == 'mysql')
    Chef::Log.warn('Your root db password is not secure and you are not running under vagrant - check your configuration')
  end
end

# Actual management is done in the mysql cookbook based on the attributes defined
