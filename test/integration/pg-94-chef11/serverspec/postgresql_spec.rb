require 'spec_helper'

master_tests('9.4')
create_users_tests('9.4')
create_database_tests('9.4')
slave_tests('9.4')
cloud_backup_tests
