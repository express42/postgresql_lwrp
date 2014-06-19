if defined?(ChefSpec)
  def create_postgresql(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql, :create, resource_name)
  end
  def create_postgresql_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql_user, :create, resource_name)
  end
  def create_postgresql_database(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql_database, :create, resource_name)
  end
end
