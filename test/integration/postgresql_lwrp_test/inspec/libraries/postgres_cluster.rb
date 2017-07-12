# encoding: utf-8
# author: Dmitry Mischenko

class PostgresCluster < Inspec.resource(1)
  name 'postgres_cluster'
  desc 'Use the postgres_cluster InSpec audit resource to test PostgreSQL database cluster status'
  example "
    describe postgres_cluster('slave') do
      it { should be_running }
    end

    describe postgres_cluster('slave2') do
      it { should be_stopped }
    end
  "

  def initialize(name)
    @name = name
    @version = version_from_psql
    @running = 0
    @stopping = case @version
                when '9.1'
                  1
                else
                  3
                end
  end

  def running?
    psql_cmd = "su postgres -c \"/usr/lib/postgresql/#{@version}/bin/pg_ctl -D /var/lib/postgresql/#{@version}/#{@name} status\""
    return true if inspec.command(psql_cmd).exit_status == @running
    false
  end

  def stopped?
    psql_cmd = "su postgres -c \"/usr/lib/postgresql/#{@version}/bin/pg_ctl -D /var/lib/postgresql/#{@version}/#{@name} status\""
    return true if inspec.command(psql_cmd).exit_status == @stopping
    false
  end

  def to_s
    "Cluster #{@name}"
  end

  private

  def version_from_psql
    return unless inspec.command('psql').exist?
    inspec.command("psql --version | head -n 1 | awk '{ print $NF }' | awk -F. '{ print $1\".\"$2 }'").stdout.strip
  end
end
