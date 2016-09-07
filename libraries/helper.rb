#
# Helpers for the cookbook
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
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

class Chef::Recipe::IngeneratorMysqlHelper
  
  # Check if provisioning is running inside a vagrant instance - pass in the node
  # to check.
  def self.is_vagrant?(node)
    node['etc'] && node['etc']['passwd'] && node['etc']['passwd']['vagrant']
  end
  
  # Gets the current root account connection details
  def self.root_connection(node)
    unless node['mysql'] && node['mysql']['server_root_password']
      raise ArgumentError.new('No root password defined in node.mysql.server_root_password')
    end
    
    {
      :host     => '127.0.0.1',
      :username => 'root',
      :password => node['mysql']['server_root_password'],
    }
  end
end
