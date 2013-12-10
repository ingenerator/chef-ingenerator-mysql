# Custom matchers for resources that don't define their own
def create_mysql_database(name)
  ChefSpec::Matchers::ResourceMatcher.new(:mysql_database, :create, name)
end
