require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

RUNNING = 0
STOPPED = 3

def postgresql_cluster(version, name)
  command("su postgres -c \"/usr/lib/postgresql/#{version}/bin/pg_ctl -D /var/lib/postgresql/#{version}/#{name} status\"").exit_status
end
