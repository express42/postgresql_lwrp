require 'chef/resource'

class Chef
  class Resource
    class PostgresqlDatabase < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgresql_database
        @provider = Chef::Provider::PostgresqlDatabase
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

      def owner(arg = nil)
        set_or_return(:owner, arg, kind_of: String)
      end

      def tablespace(arg = nil)
        set_or_return(:tablespace, arg, kind_of: String)
      end

      def template(arg = nil)
        set_or_return(:template, arg, kind_of: String)
      end

      def encoding(arg = nil)
        set_or_return(:encoding, arg, kind_of: String)
      end

      def connectionn_limit(arg = nil)
        set_or_return(:connectionn_limit, arg, kind_of: Integer)
      end
    end
  end
end
