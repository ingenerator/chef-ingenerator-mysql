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
default['project']['services']['db']['schema']           = node.ingenerator_project_name()
default['project']['services']['db']['user']             = node.ingenerator_project_name()
default['project']['services']['db']['password']         = 'mysql-appuser'

# If set, the application database user can connect from anywhere
default['project']['services']['db']['connect_anywhere'] = false

# Configure the default mysql database privileges the app user should have - restricted by default
# All available privileges are in the hash, first set to false and then the required privs are true
# Assign an override value to remove or grant different privileges for your app - but consider
# whether you should instead be running privileged db code in a non-web process on its own user
['CREATE', 'DROP', 'LOCK TABLES', 'EVENT', 'ALTER', 'DELETE', 'INDEX', 'INSERT', 'SELECT',
 'UPDATE', 'CREATE TEMPORARY TABLES', 'TRIGGER', 'CREATE VIEW', 'SHOW VIEW', 'ALTER ROUTINE',
 'CREATE ROUTINE', 'EXECUTE', 'FILE', 'CREATE TABLESPACE', 'CREATE USER', 'PROCESS', 'PROXIES',
 'RELOAD', 'REPLICATION CLIENT', 'REPLICATION SLAVE', 'SHOW DATABASES', 'SHUTDOWN', 'SUPER'].each do |privilege|
  default['project']['services']['db']['privileges'][privilege] = false
end

['LOCK TABLES', 'DELETE', 'INSERT', 'SELECT', 'UPDATE', 'EXECUTE'].each do |privilege|
  default['project']['services']['db']['privileges'][privilege] = true
end

# --- Language and application bindings
# Trigger PHP to install the php5-mysql package
default['php']['module_packages']['php5-mysql'] = true
