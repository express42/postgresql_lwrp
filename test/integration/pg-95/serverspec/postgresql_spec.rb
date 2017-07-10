require 'spec_helper'

master_tests('9.5')
create_users_tests('9.5')
create_database_tests('9.5')
install_extension_tests('9.5')
slave_tests('9.5')
cloud_backup_tests
