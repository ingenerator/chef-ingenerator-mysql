# Installs the mysql2 gem into chef, working around the segfault when compiling against 5.7.28
#
# The segfault appears to be caused by mismatches between Chef's embedded libs - potentially openssl - and the ones
# at system level.
#
# The easiest fix seems to be to bake the old mysql 5.7.27 into chef's include path so that it compiles the gem against
# the older libraries that come with chef.

cookbook_file '/opt/chef/embedded/libmysqlclient-dev.5.7.27.tar.gz' do
  action :create_if_missing
  notifies :run, 'execute[unpack libmysqlclient libs and includes for chef]', :immediate
end

execute 'unpack libmysqlclient libs and includes for chef' do
  action   :nothing
  cwd      '/opt/chef/embedded'
  command  <<-EOM
    echo "Unpacking libmysqlclient-dev.5.7.27" &&
    mkdir libmysqlclient-dev.5.7.27 &&
    tar -xf libmysqlclient-dev.5.7.27.tar.gz --directory libmysqlclient-dev.5.7.27 &&
    echo "Creating symlinks" &&
    ln -s /opt/chef/embedded/libmysqlclient-dev.5.7.27/include/mysql /opt/chef/embedded/include/mysql &&
    ln -s /opt/chef/embedded/libmysqlclient-dev.5.7.27/lib/libmysqlclient.so.20.3.14 /opt/chef/embedded/lib/libmysqlclient.so &&
    ln -s /opt/chef/embedded/libmysqlclient-dev.5.7.27/lib/libmysqlclient.so.20.3.14 /opt/chef/embedded/lib/libmysqlclient.so.20 &&
    ln -s /opt/chef/embedded/libmysqlclient-dev.5.7.27/lib/libmysqlclient.so.20.3.14 /opt/chef/embedded/lib/libmysqlclient.so.20.3.14 &&
    ln -s /opt/chef/embedded/libmysqlclient-dev.5.7.27/lib/pkgconfig/mysqlclient.pc /opt/chef/embedded/lib/pkgconfig/mysqlclient.pc &&
    echo "Symlinks all created"
  EOM
  notifies :run, 'execute[install and compile chef mysql2 gem]', :immediate
end

execute 'install and compile chef mysql2 gem' do
  action :nothing
  command '/opt/chef/embedded/bin/gem install mysql2 -v 0.5.2 -- --with-ldflags="-L/opt/chef/embedded/lib/ -R/opt/chef/embedded/lib/" --with-cppflags=-I/opt/chef/embedded/include/'
end
