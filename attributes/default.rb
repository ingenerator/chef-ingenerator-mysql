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

# By default bind only to 127.0.0.1 - override for external access (or access over ssh forwarding)
default['mysql']['bind_address'] = '127.0.0.1'

# Set the default_server_socket attribute so that anything that was using it can continue to do so
# NOTE however that this MUST NOT be changed or it will probably cause all manner of grief with us
# using auth-sockets and the change it might move between package install and mysql configuration
default['mysql']['default_server_socket'] = '/var/run/mysqld/mysqld.sock'

# Set the data_dir for anything that needs to reference it
# NOTE this MUST NOT be changed - it will have NO IMPACT on mysql config and will BREAK everything else
# If you want the data in a custom path, provision a permanent bind mount to this location BEFORE you install mysql
default['mysql']['data_dir'] = '/var/lib/mysql'

# Ensure that apt update runs at compile-time, to prevent issues with installing the mysql client
# (see https://github.com/opscode-cookbooks/apt/pull/75)
default['apt']['compile_time_update'] = true

# Configure as required - this should usually be the same as the default tz used
# in your application
default['mysql']['default-time-zone'] = 'Europe/London'

# On a local development box, provision rooty access for the vagrant user by default
if is_environment?(:localdev)
  default['mysql']['local_admins']['vagrant']['create'] = true
  default['mysql']['local_admins']['vagrant']['privileges'] = [:all]
end
