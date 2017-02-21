if defined?(ChefSpec)

  ChefSpec.define_matcher :mysql_default_timezone

  def configure_mysql_default_timezone(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:mysql_default_timezone, :configure, resource_name)
  end

  def create_user_mysql_config(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_mysql_config, :create, resource_name)
  end
end
