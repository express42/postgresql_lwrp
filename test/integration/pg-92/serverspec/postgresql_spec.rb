require 'spec_helper'

master_tests('9.2')
create_users_tests('9.2')
create_database_tests('9.2')
slave_tests('9.2')
cloud_backup_tests
