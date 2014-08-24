require 'chef/resource'

class Chef
  class Resource
    class PostgresqlUser < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgresql_user
        @provider = Chef::Provider::PostgresqlLwrpUser
        @action = :create
        @allowed_actions = [:create]
        @name = name
      end

      def name(arg = nil)
        set_or_return(:name, arg, kind_of: String, required: true)
      end

      def in_version(arg = nil)
        set_or_return(:in_version, arg, kind_of: String, required: true)
      end

      def in_cluster(arg = nil)
        set_or_return(:in_cluster, arg, kind_of: String, required: true)
      end

      def unencrypted_password(arg = nil)
        set_or_return(:unencrypted_password, arg, kind_of: String)
      end

      def encrypted_password(arg = nil)
        set_or_return(:encrypted_password, arg, kind_of: String)
      end

      def replication(arg = nil)
        set_or_return(:replication, arg, kind_of: [TrueClass, FalseClass])
      end

      def superuser(arg = nil)
        set_or_return(:superuser, arg, kind_of: [TrueClass, FalseClass])
      end

      def advanced_options(arg = nil)
        set_or_return(:advanced_options, arg, kind_of: Hash, default: {})
      end
    end
  end
end
