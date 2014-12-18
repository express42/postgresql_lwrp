## 1.1.1 (Dec 18, 2014)
* (New) Add postgresql 9.4 components
* (Fix) Fix Test Kitchen boxes
* (Fix) Fix postgresql start after reboot

## 1.1.0 (Dec 10, 2014)
* (New) Add cloud backup lwrp, using wal-e for cloud backup

## 1.0.1 (Oct 31, 2014)
* (Fix) Fix broken allow_restart_cluster option

## 1.0.0 (Aug 25, 2014)

* (New) Flat configuration file
* (New) Initial replicaton can be started automatically
* (New) Option allow_restart_cluster allows do restart instead reload (Only first time or always)
* (New) Resources/providers for database and user creation
* (New) Recipe apt_official_repository with official postgresql repository
* (New) Severspec tests added
* (Removed) Removed databags for users and databases. You should use appropriate providers
* (Fix) pg_ident template fixed

## 0.2.3 (Jun 18, 2013)

### Minor fixes

* Cluster create options were defined as Hash and accessed as Mash.
* pg_hba.conf became faulty on long db/user names or other line fields.
* Examples in readme was badly formatted and contained small syntax issues.
* ssl was hardcoded to postgresql.conf.

## 0.2.2 (May 8, 2013)

### Minor fixes

* Check cluster_create_options hash for key before accessing it.

## 0.2.1 (Apr 14, 2013)

### Minor fixes

* Style fixes to satisfy foodcritic wishes

## 0.2.0 (Apr 14, 2013)

### Improvements

* Set LANG from cluster_create for postgresql package install(used in pg_clustercreate in debian scripts)
