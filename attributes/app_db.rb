#
# Configures settings for applications that use a mysql database server - credentials, schema,
# required language extensions etc.
#
#
# Author:: Andrew Coulton(<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Attribute:: app_db
#
# Copyright 2012-13, Opscode, Inc.
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

# Credentials that are used to create the application db user and manage app config files
# At least the password needs to be overridden to something secure in a production environment
project_name = (node['project'] && node['project']['name']) || 'ingenerator'
default['project']['services']['db']['schema']   = project_name
default['project']['services']['db']['user']     = project_name
default['project']['services']['db']['password'] = project_name

# Trigger PHP to install the php5-mysql package
default['php']['module_packages']['php5-mysql'] = true
