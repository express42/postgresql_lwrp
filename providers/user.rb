#
# Cookbook Name:: postgresql_lwrp
# Provider:: user
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) 2014 LLC Express 42
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#

use_inline_resources

include Chef::Postgresql::Helpers

provides :postgresql_user if defined? provides

action :create do
  options = new_resource.advanced_options.clone

  if new_resource.replication == true
    options['REPLICATION'] = nil
  elsif new_resource.replication == false
    options['NOREPLICATION'] = nil
  end

  if new_resource.superuser == true
    options['SUPERUSER'] = nil
  elsif new_resource.superuser == false
    options['NOSUPERUSER'] = nil
  end

  options['ENCRYPTED PASSWORD'] = "'#{new_resource.encrypted_password}'" if new_resource.encrypted_password

  options['UNENCRYPTED PASSWORD'] = "'#{new_resource.unencrypted_password}'" if new_resource.unencrypted_password

  if create_user(new_resource.in_version, new_resource.in_cluster, new_resource.name, options)
    new_resource.updated_by_last_action(true)
  end
end
