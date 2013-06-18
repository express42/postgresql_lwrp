Description
===========
This cookbook includes recipes and provider to install and configure postgresql database. This cookbook was tested with Postgresql 9.1 and 9.2, and should work with 9.0 too.

Changelog
=========
See CHANGELOG.md

Requirements
============
- This cookbook version (0.2.x) tested only on Debian squeeze and Ubuntu 12.04.
- You must have apt repository with Postgres version 9.x

Attributes
==========
This cookbook have server and client attribute files.

With client attributes(["postgresql"]["client"]) you can set only postgresql client and library version.

Server attributes are starting from ["postgresql"]["defaults"] and used as default attributes for postgresql provider. You should not override this defaults, you can pass your settings to provider instead.

Resources/Providers
===================
# Actions
- :create: creates postgresql cluster

# Attribute Parameters

- `cluster_name`: name attribute. Cluster name (e.g. main).
- `cookbook`: cookbook for templates. Skip this for default templates.
- `databag`: data bag for users and databases, if you don't want create users or databases with chef you can skip this.
- `cluster_create_options`: options for pg_createcluster (only locale related options)
- `configuration`: Hash with configuration options for postgresql. Configuration divided to sections, see examples.
- `hba_configuration`: Array with hba configuration, see examples.
- `ident_configuration`: Array with ident configuration, see examples.
- `replication`: Hash with replication configuration. Now provider supports only streaming replication. See examples. Cluster must be copied manually before chef run.
- `ssl_certificate`: Accepts either Hash or String. Sting is treated like data bag item's name. Hash is treated like the options set for self-signed certificate generation. See [Ssl_certificate details](#ssl_certificate-attribute) section for more details.

### ssl_certificate attribute

Accepted value types are:

* `Hash`
* `String`

Default value is Hash:

```ruby
{
  :subj => {
    :C => 'RU',
    :ST => 'Moscow',
    :L => 'Moscow',
    :O => 'Example Inc.',
    :CN => 'localhost'
  },
  :keysize => 2048
}
```

These are values that are used to generate self-signed ssl certificate.

Your Hash will be merged with default one. So you can safely redefine any or all of these options.

If you specify the `String` instead of `Hash` it will be treated as the name for encrypted data bag item which stores your certificate. Data bag item is searched inside **site_certificates** data bag.

Data bag format is:

```json
{
  "id": "exampleid",
  "certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n",
  "private_key": "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"
}
```

Certificate files will be created only once - after initial PG cluster creation.

Examples
========

### Master-Slave configuration.

Master:

```ruby
postgresql "main" do
  cluster_create_options( "locale" => "ru_RU.UTF-8" )
  configuration(
    :version => "9.1",
    :connection => {
      :listen_addresses        => "'192.168.0.1'",
      :max_connections         => 300,
      :ssl_renegotiation_limit => 0
    },
    :resources => {
      :shared_buffers       => "512MB",
      :maintenance_work_mem => "64MB",
      :work_mem             => "8MB"
    },
    :queries => { :effective_cache_size => "512MB" },
    :wal     => { :checkpoint_completion_target => "0.9" },
    :logging => { :log_min_duration_statement => "200" }
  )
  hba_configuration(
    [
      { :type => "host", :database => "all", :user => "all", :address => "192.168.0.0/24", :method => "md5" },
      { :type => "host", :database => "replication", :user => "postgres", :address => "192.168.0.10/32", :method => "trust" }
    ]
  )
end
```

Slave:

```ruby
postgresql "main" do
  cluster_create_options( "locale" => "ru_RU.UTF-8" )
  configuration(
    :version => "9.1",
    :connection => {
      :listen_addresses        => "'192.168.0.10'",
      :max_connections         => 300,
      :ssl_renegotiation_limit => 0
    },
    :resources => {
      :shared_buffers       => "512MB",
      :maintenance_work_mem => "64MB",
      :work_mem             => "8MB"
    },
    :queries => { :effective_cache_size => "512MB" },
    :wal     => { :checkpoint_completion_target => "0.9" },
    :logging => { :log_min_duration_statement => "200" },
    :standby => { :hot_standby => "on" }
  )
  hba_configuration(
    [
      { :type => "host", :database => "all", :user => "all", :address => "192.168.0.0/24", :method => "md5" },
      { :type => "host", :database => "replication", :user => "postgres", :address => "192.168.0.10/32", :method => "trust" }
    ]
  )
  replication(
    :standby_mode =>"on",
    :primary_conninfo => "host=192.168.0.1",
    :trigger_file => "/tmp/pgtrigger"
  )
end
```

### SSL Certificate options:

```ruby
postgresql "main" do
  cluster_create_options( "locale" => "ru_RU.UTF-8" )
  configuration(
    :version => "9.1",
    :connection => { :listen_addresses => "'192.168.0.1'", :ssl_renegotiation_limit => 0 },
    :resources => { :shared_buffers => "512MB", :maintenance_work_mem => "64MB", :work_mem => "8MB" },
    :queries => { :effective_cache_size => "512MB" }
  )
  ssl_certificate(
    :subj => {
      :CN => node['fqdn']
    },
    :keysize => 4096
  )
end
```

```ruby
postgresql "main" do
  cluster_create_options( "locale" => "ru_RU.UTF-8" )
  configuration(
    :version => "9.1",
    :connection => { :listen_addresses => "'192.168.0.1'", :ssl_renegotiation_limit => 0 },
    :resources => { :shared_buffers => "512MB", :maintenance_work_mem => "64MB", :work_mem => "8MB" },
    :queries => { :effective_cache_size => "512MB" }
  )
  ssl_certificate("example-com-ssl-files")
end
```

License and Author
==================

Author:: Nikita Borzykh (<nikita@express42.com>)

Copyright (C) 2012-2013 LLC Express 42

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
