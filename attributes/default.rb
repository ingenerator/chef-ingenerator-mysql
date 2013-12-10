#
# General attribute settings for mysql and related recipes/resources
#
# Author:: Andrew Coulton(<andrew@ingenerator.com>)
# Cookbook Name:: ingenerator-mysql
# Attribute:: default
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

# Define insecure root passwords for dev boxes. These MUST be upgraded to secure for production
default['mysql']['server_debian_password'] = 'mysql'
default['mysql']['server_root_password']   = 'mysql'
default['mysql']['server_repl_password']   = 'mysql'

# Define the bind port - default to localhost-only in production for security
default['mysql']['bind_address'] = '127.0.0.1'
