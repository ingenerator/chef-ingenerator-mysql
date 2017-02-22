if defined?(ChefSpec)

  ChefSpec.define_matcher :mysql_default_timezone

  def create_application_database(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:application_database, :create, resource_name)
  end

  def configure_mysql_default_timezone(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:mysql_default_timezone, :configure, resource_name)
  end

  def create_mysql_local_admin(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:mysql_local_admin, :create, resource_name)
  end

  def create_user_mysql_config(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_mysql_config, :create, resource_name)
  end
end
