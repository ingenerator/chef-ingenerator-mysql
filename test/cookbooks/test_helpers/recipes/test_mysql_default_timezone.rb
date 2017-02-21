mysql_default_timezone node['test']['timezone'] do
  credential_file node['test']['credential_file'] if node['test']['credential_file']
end
