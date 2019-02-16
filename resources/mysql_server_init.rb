resource_name :mysql_server_init

property :data_dir, String, default: '/var/lib/mysql'


action :secure_db do
  unless is_test_database_removed?
    converge_by do
      shell_out!('mysql', :input => secure_init_sql)
    end
  end
#  ruby_block 'initialise mysql' do
#    not_if { mysql_initialised? }
#    block do
#      puts shell_out!(
#        'mysql',
#        :input => secure_init_sql,
#        :environment => {'HOME' => '/dev/null'}
#        ).stdout
#    end
#  end
end

action :import_timezones do
  execute 'populate mysql timezones' do
    command "mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --database=mysql"
    only_if "mysql --database=mysql -e'SELECT COUNT(*) AS tzs FROM mysql.time_zone \\G' | grep 'tzs: 0'"
  end
end

action_class do
  def secure_init_sql
    sql = [
      # Just use auth sockets instead of a password for root. If we really need a password here's how we'd do it
      # "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{sql_escaped_password}';",
      "DELETE FROM mysql.user WHERE USER LIKE '';",
      "DELETE FROM mysql.user WHERE user = 'root' and host NOT IN ('127.0.0.1', 'localhost');",
      "FLUSH PRIVILEGES;",
      "DELETE FROM mysql.db WHERE db LIKE 'test%';",
      "DROP DATABASE IF EXISTS test ;",
    ]
    sql.join("\n")
  end

  def is_test_database_removed?
    databases = shell_out!('mysql --vertical -e"SHOW DATABASES LIKE \'test%\'"').stdout
    ! /test/.match(databases)
  end

end