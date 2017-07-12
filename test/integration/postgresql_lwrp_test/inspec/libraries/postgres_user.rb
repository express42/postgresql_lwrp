# encoding: utf-8
# author: Dmitry Mischenko

class PostgresUser < Inspec.resource(1)
  name 'postgres_user'
  desc 'Use the postgres_user InSpec audit resource to test PostgreSQL database user options'
  example "
    describe postgres_user('test-02', 'test-02') do
      it { should have_login }
      it { should have_privilege('rolsuper') }
    end
  "

  def initialize(user, pass, host = nil, port = nil, db = nil)
    @user = user || 'postgres'
    @pass = pass
    @host = host || 'localhost'
    @db = db || ['postgres']
    @version = version_from_psql
    @cluster = cluster_from_dir("/etc/postgresql/#{@version}")
    @port = port || get_port(@version, @cluster)
  end

  def has_privilege?(priv)
    return true if query("SELECT #{priv} FROM pg_roles where rolname='#{@user}'") == 't'
    false
  end

  def has_login?
    return true if query('SELECT 1')
    false
  end

  def to_s
    "User #{@user}"
  end

  private

  #
  def query(query)
    psql_cmd = create_psql_cmd(query, @db)
    cmd = inspec.command(psql_cmd)
    out = cmd.stdout + "\n" + cmd.stderr
    if cmd.exit_status != 0 || out =~ /could not connect to .*/ || out.downcase =~ /^error:.*/
      false
    else
      cmd.stdout.strip
    end
  end

  def escaped_query(query)
    Shellwords.escape(query)
  end

  def create_psql_cmd(query, db = [])
    dbs = db.map { |x| "-d #{x}" }.join(' ')
    "PGPASSWORD='#{@pass}' psql -U #{@user} #{dbs} -h #{@host} -p #{@port} -A -t -c #{escaped_query(query)}"
  end

  def get_port(version, cluster)
    postmaster_content = inspec.command("cat /var/lib/postgresql/#{version}/#{cluster}/postmaster.pid").stdout.split
    postmaster_content[3].to_i
  end

  def version_from_psql
    return unless inspec.command('psql').exist?
    inspec.command("psql --version | head -n 1 | awk '{ print $NF }' | awk -F. '{ print $1\".\"$2 }'").stdout.strip
  end

  def cluster_from_dir(dir)
    if inspec.directory("#{dir}/main").exist?
      'main'
    else
      dirs = inspec.command("ls -d #{dir}/*/").stdout.lines
      first = dirs.first.chomp.split('/').last
      if dirs.count > 1
        warn "Multiple postgresql clusters configured or incorrect base dir #{dir}"
        warn "Using the first directory found: #{first}"
      end
      first
    end
  end
end
