#
# Configures paths and actions for the mysql development database
#
#
# Author:: Andrew Coulton(<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Attribute:: dev_db
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

# Whether to always recreate the development db - if not will only be recreated if the SQL files change
if ENV.fetch('RECREATE_DEV_DB', false) || is_environment?(:buildslave)
  default['mysql']['dev_db']['recreate_always'] = true
else
  default['mysql']['dev_db']['recreate_always'] = false
end

# Local path to place copies of the current dev schema files
default['mysql']['dev_db']['schema_path'] = '/var/mysql/mysql_dev_schema'

# SQL files to provision - scoped with a cookbook name like a recipe eg
# default['mysql']['dev_db']['sql_files']['application::dev_db/table.sql'] = true
default['mysql']['dev_db']['sql_files'] = {}
