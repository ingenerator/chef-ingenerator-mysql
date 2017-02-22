mysql_local_admin  node['test']['user'] do
  password         node['test']['password'] if node['test']['password']
  home_directory   node['test']['homedir'] if node['test']['homedir']
  default_database node['test']['db'] if node['test']['db']
  privileges       node['test']['privileges'] if node['test']['privileges']
end
