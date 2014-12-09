require 'chef/resource'

class Chef
  class Resource
    class PostgresqlCloudBackup < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgresql_cloud_backup
        @provider = Chef::Provider::PostgresqlLwrpCloudBackup
        @action = :schedule
        @allowed_actions = [:schedule]
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

      def protocol(arg = nil)
        set_or_return(:protocol, arg, kind_of: String, required: true, callbacks: {
                        'is not allowed! Allowed providers: s3, swift or azure' => proc do |value|
                          !value.to_sym.match(/^(s3|swift|azure)$/).nil?
                        end
                      })
      end

      def params(arg = nil)
        set_or_return(:credentials, arg, kind_of: Hash, required: true)
      end

      def full_backup_time(arg = nil)
        set_or_return(:full_backup_time, arg, kind_of: Hash, default: { minute: '0', hour: '3', day: '*', month: '*', weekday: '*' })
      end
    end
  end
end
