if defined?(ChefSpec)

  def create_user_mysql_config(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_mysql_config, :create, resource_name)
  end
end
