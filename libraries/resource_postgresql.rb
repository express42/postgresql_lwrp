require 'chef/resource'

class Chef
  class Resource
    class Postgresql < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgresql
        @provider = Chef::Provider::Postgresql
        @action = :create
        @allowed_actions = [:create]
        @cluster_name = name
      end

      def cluster_name(arg = nil)
        set_or_return(:cluster_name, arg, kind_of: String, required: true)
      end

      def cluster_version(arg = nil)
        set_or_return(:cluster_version, arg, kind_of: String, regex: [/\A(|\d.\d)\Z\z/], default: '')
      end

      def cookbook(arg = nil)
        set_or_return(:cookbook, arg, kind_of: String, default: 'postgresql')
      end

      def cluster_create_options(arg = nil)
        set_or_return(:cluster_create_options, arg, kind_of: Hash, default: {})
      end

      def configuration(arg = nil)
        set_or_return(:configuration, arg, kind_of: Hash, default: {})
      end

      def hba_configuration(arg = nil)
        set_or_return(:hba_configuration, arg, kind_of: Array, default: [])
      end

      def ident_configuration(arg = nil)
        set_or_return(:ident_configuration, arg, kind_of: Array, default: [])
      end

      def replication(arg = nil)
        set_or_return(:replication, arg, kind_of: Hash, default: {})
      end

      def replication_initial_copy(arg = nil)
        set_or_return(:replication_initial_copy, arg, kind_of: [TrueClass, FalseClass], default: false)
      end

      def replication_start_slave(arg = nil)
        set_or_return(:replication_start_slave, arg, kind_of: [TrueClass, FalseClass], default: false)
      end

      def allow_restart_cluster(arg = nil)
        set_or_return(:allow_restart_cluster, arg, default: :none,
                                                   callbacks: {
                                                     'Allowed params for allow_restart_cluster: first, always or none' => proc do |value|
                                                       return true if value.match(/^(first|always|none)$/) == 0
                                                       return false if value.match(/^(first|always|none)$/) != 0
                                                     end
                                                   }
        )
      end
    end
  end
end
