[![Chef cookbook](https://img.shields.io/cookbook/v/postgresql_lwrp.svg)](https://github.com/express42/postgresql_lwrp)
[![Code Climate](https://codeclimate.com/github/express42/postgresql_lwrp/badges/gpa.svg)](https://codeclimate.com/github/express42/postgresql_lwrp)
[![Build Status](https://travis-ci.org/express42/postgresql_lwrp.svg)](https://travis-ci.org/express42/postgresql_lwrp)

Description
===========
This cookbook includes recipes and providers to install and configure postgresql database. This cookbook was tested with Postgresql 9.1, 9.2, 9.3, 9.4, 9.5, 9.6 & 10.
Supported platforms: Debian Jessie/Stretch and Ubuntu 14.04/16.04.

Changelog
=========
See CHANGELOG.md

Requirements
============

The minimal recommended version of chef-client is `13.0.113`. It may still work on version `12.5.1` and older, but no tests are made starting from version `1.3.0` of this cookbook as Chef 12 is reaching its EOL in the April, 2018

Dependencies
============

* apt
* cron
* poise-python

Attributes
==========
This cookbook have server and client attribute files.

With client attributes(["postgresql"]["client"]) you can set only postgresql client and library version.

Server attributes are starting from ["postgresql"]["defaults"] and used as default attributes for postgresql provider. You should not override this defaults, you can pass your settings to provider instead.

Resources/Providers
===================

### Resource: default

#### Actions

- :create: creates postgresql cluster

#### Resource parameters

- cluster_name: name attribute. Cluster name (e.g. main). Be aware, systemd (in Ubuntu 16.04 and Debian Jessie) not working with cluster names that containing dashes ('-').
- cluster_version: set cluster version
- cookbook: cookbook for templates. Skip this for default templates.
- cluster_create_options: options for pg_createcluster (only locale related options)
- configuration: Hash with configuration options for postgresql, see examples.
- hba_configuration: Array with hba configuration, see examples.
- ident_configuration: Array with ident configuration, see examples.
- replication: Hash with replication configuration. See replication example.
- replication_initial_copy: Boolean. If `true` pg_basebackup will be exec to make initial replication copy. Default is `false`.
- replication_start_slave: Boolean. If `true` slave cluster will be started after creation. Should be used with replication_initial_copy option. Default `false`.
- allow_restart_cluster: Can be `first`, `always` or `none`. Specifies when cluster must restart instead of reload. `first` – only first time after installation. `always` – always restart, even if changes doesn't require restart. `none` - never, use reload every time. Default is `none`.


Other
=====
### Cloud backup helper:

`postgresql_cloud_backup_helper.sh` helper can be found at `/opt/wal-e/bin/`.

#### Usage:

`postgresql_cloud_backup_helper.sh <cluster_name> <cluster_version> last|count`

- `cluster_name` – postgresql cluster name (ex. *main*)
- `cluser_version` – postgresql cluser version (ex. 9.3)
- `last` – shows last backup time
- `count` – shows total number of backups.

Examples
========
Example master database setup:

```ruby
postgresql 'main' do
  cluster_version '9.3'
  cluster_create_options( locale: 'ru_RU.UTF-8' )
  configuration(
      listen_addresses:           '192.168.0.2',
      max_connections:            300,
      ssl_renegotiation_limit:    0,
      shared_buffers:             '512MB',
      maintenance_work_mem:       '64MB',
      work_mem:                   '8MB',
      log_min_duration_statement: 200
  )
  hba_configuration(
    [
      { type: 'host', database: 'all', user: 'all', address: '192.168.0.0/24', method: 'md5' },
      { type: 'host', database: 'replication', user: 'postgres', address: '192.168.0.3/32', method: 'trust' }
    ]
  )
end
```

Example slave database setup:

```ruby
postgresql 'main' do
   cluster_version '9.3'
  cluster_create_options( locale: 'ru_RU.UTF-8' )
  configuration(
      listen_addresses:           '192.168.0.3',
      max_connections:            300,
      ssl_renegotiation_limit:    0,
      shared_buffers:             '512MB',
      maintenance_work_mem:       '64MB',
      work_mem:                   '8MB',
      log_min_duration_statement: 200
  )
  hba_configuration(
    [
      { type: 'host', database: 'all', user: 'all', address: '192.168.0.0/24', method: 'md5' },
      { type: 'host', database: 'replication', user: 'postgres', address: '192.168.0.2/32', method: 'trust' }
    ]
  )
  replication(
    standby_mode: 'on',
    primary_conninfo: 'host=192.168.0.1',
    trigger_file: '/tmp/pgtrigger'
  )
  replication_initial_copy true
  replication_start_slave true
end
```

Example slave configuration with replication slots (PostgreSQL >= 9.4)

```ruby
replication(
  standby_mode: 'on',
  primary_conninfo: 'host=192.168.0.1',
  trigger_file: '/tmp/pgtrigger'
  primary_slot_name: 'some_slot_on_master'
)
```
Don't forget to create slot on master server before:

```sql
# SELECT pg_create_physical_replication_slot('some_slot_on_master');
```

Example users and databases setup

```ruby
postgresql_user 'user01' do
  in_version '9.3'
  in_cluster 'main'
  unencrypted_password 'user01password'
end

postgresql_database 'database01' do
  in_version '9.3'
  in_cluster 'main'
  owner 'user01'
end
```

Example full daily database backup

```ruby
postgresql_cloud_backup 'main' do
  in_version '9.3'
  in_cluster 'main'
  full_backup_time weekday: '*', month: '*', day: '*', hour: '3', minute: '0'
  # Data bag item should contain following keys for S3 protocol:
  # aws_access_key_id, aws_secret_access_key, wale_s3_prefix
  parameters Chef::EncryptedDataBagItem.load('s3', 'secrets').to_hash.select {|i| i != "id"}
  # Or just a hash, if you don't use data bags:
  parameters { aws_access_key_id: 'access_key', aws_secret_access_key: 'secret_key', wale_s3_prefix: 's3_prefix' }
  protocol 's3'
  # In case you need to prepend wal-e with, for example, traffic limiter
  # you can use following method:
  command_prefix 'trickle -s -u 1024'
  # It will be prepended to resulting wal-e execution in cron task
end
```

Example usage of cloud backup helper usage

```bash
$ /opt/wal-e/bin/postgresql_cloud_backup_helper.sh main 9.3 last
1428192159
$ /opt/wal-e/bin/postgresql_cloud_backup_helper.sh main 9.3 count
31
```

Example of how to install extensions from postgresql-contrib
NOTE: schema and version are optional parameters, but others are required

```ruby
postgresql_extension 'cube' do
  in_version '9.4'
  in_cluster 'main'
  db 'test01'
  schema 'public'
end
```
Example of how to install extensions from http://pgxn.org/
NOTE: schema is an optional parameter, but others are required

```ruby
pgxn_extension 'pg_lambda' do
  in_version '9.4'
  in_cluster 'main'
  db 'test01'
  version '1.0.2'
  stage 'stable'
end
```


# License and Maintainer

Maintainer:: LLC Express 42 (<cookbooks@express42.com>)
Source:: https://github.com/express42/postgresql_lwrp
Issues:: https://github.com/express42/postgresql_lwrp/issues

License:: MIT
