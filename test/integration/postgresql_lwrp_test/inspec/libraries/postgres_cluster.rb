# author: Dmitry Mischenko

class PostgresCluster < Inspec.resource(1)
  name 'postgres_cluster'
  desc 'Use the postgres_cluster InSpec audit resource to test PostgreSQL database cluster status'
  example "
    describe postgres_cluster('9.6', 'slave') do
      it { should be_running }
    end

    describe postgres_cluster('9.6', 'slave2') do
      it { should be_stopped }
    end
  "

  def initialize(version, name = 'main')
    @name = name
    @version = version
    @port = get_port(version, name)
    @running = 0
    @stopping = define_stopping_code(version)

    @params = SimpleConfig.new(
      running_configuration,
      assignment_regex: /^\s*([^=\|]*?)\s*\|\s*(.*?)\s*$/
    )
  end

  def running?
    cmd = "/usr/lib/postgresql/#{@version}/bin/pg_ctl"
    cmd += " -D /var/lib/postgresql/#{@version}/#{@name} status"
    full_cmd = su_wrapper(cmd)
    return true if inspec.command(full_cmd).exit_status == @running
    false
  end

  def stopped?
    cmd = "/usr/lib/postgresql/#{@version}/bin/pg_ctl"
    cmd += " -D /var/lib/postgresql/#{@version}/#{@name} status"
    full_cmd = su_wrapper(cmd)
    return true if inspec.command(full_cmd).exit_status == @stopping
    false
  end

  def to_s
    "Cluster #{@name}"
  end

  # Expose all parameters of the configuration file.
  def method_missing(name)
    @params.params[name.to_s] || super
  end

  def respond_to_missing?(method_name, include_private = false)
    @params.params.include?(method_name.to_s) || super
  end

  private

  def running_configuration
    c = query('SELECT name, setting FROM pg_settings')
    c
  end

  def query(query)
    psql_cmd = create_psql_cmd(query, 'postgres')
    cmd = inspec.command(psql_cmd)
    out = cmd.stdout + "\n" + cmd.stderr

    if cmd.exit_status != 0 ||
       out =~ /could not connect to .*/ ||
       out.downcase =~ /^error:.*/
      nil
    else
      cmd.stdout.strip
    end
  end

  def escaped_query(query)
    Shellwords.escape(query)
  end

  def su_wrapper(psql_cmd)
    "su postgres -c \"#{psql_cmd}\""
  end

  def create_psql_cmd(query, database)
    cmd = '/usr/bin/psql'
    cmd += " -d #{database}"
    cmd += " -p #{@port}"
    cmd += ' -q -A -t'
    cmd += " -c #{escaped_query(query)}"
    su_wrapper(cmd)
  end

  def get_port(version, cluster)
    pid_file_name = "/var/lib/postgresql/#{version}/#{cluster}/postmaster.pid"
    postmaster_content = inspec.command("cat #{pid_file_name}").stdout.split
    postmaster_content[3].to_i
  end

  def define_stopping_code(version)
    case version.to_s
    when '9.1'
      1
    else
      3
    end
  end
end
