# encoding: utf-8
# author: Dmitry Mischenko

class PostgresUser < Inspec.resource(1)
  name 'postgres_user'
  desc 'Use the postgres_user InSpec audit resource to test PostgreSQL database user options'
  example "
    describe postgres_user('9.6', 'main', 'test-02', 'test-02') do
      it { should have_login }
      it { should have_privilege('rolsuper') }
    end
  "

  def initialize(version, cluster, user, pass, db = 'postgres')
    @user = user || 'postgres'
    @pass = pass
    @host = 'localhost'
    @db = db
    @port = get_port(version, cluster)
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

  def create_psql_cmd(query, db)
    "PGPASSWORD='#{@pass}' psql -U #{@user} -d #{db} -h #{@host} -p #{@port} -A -t -c #{escaped_query(query)}"
  end

  def get_port(version, cluster)
    postmaster_content = inspec.command("cat /var/lib/postgresql/#{version}/#{cluster}/postmaster.pid").stdout.split
    postmaster_content[3].to_i
  end
end
