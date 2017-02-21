conn_hash = {
  username: node['test']['my_user'],
  password: node['test']['my_password'],
  host:     node['test']['my_host']
}

user_mysql_config node['test']['filepath'] do
  user         node['test']['user'] unless node['test']['user'].nil?
  mode         node['test']['mode'] unless node['test']['mode'].nil?

  connection   conn_hash unless node['test']['no_connection']
  database     node['test']['my_db'] unless node['test']['my_db'].nil?

  safe_updates node['test']['safe_updates'] unless node['test']['safe_updates'].nil?
  default_charset node['test']['default_charset'] if node['test']['default_charset']
end
