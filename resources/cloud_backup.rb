#
# Cookbook Name:: postgresql_lwrp
# Resource:: cloud_backup
#
# Author:: Kirill Kouznetsov (agon.smith@gmail.com)
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

provides :postgresql_cloud_backup
resource_name :postgresql_cloud_backup

actions :schedule
default_action :schedule

attribute :name, kind_of: String, required: true
attribute :in_version, kind_of: String, required: true
attribute :in_cluster, kind_of: String, required: true
attribute :protocol, kind_of: String,
                     required: true,
                     callbacks: {
                       'is not allowed! Allowed providers: s3, swift or  azure' => proc do |value|
                         !value.to_sym.match(/^(s3|swift|azure)$/).nil?
                       end
                     }
attribute :params, kind_of: Hash, required: true

# Crontab command prefix to use with wal-e
# e.g. for speed limit by trickle like `trickle -s -u 1024 envdir /etc/wal-e.d/...`
attribute :command_prefix, kind_of: String, required: false
attribute :full_backup_time, kind_of: Hash, default: { minute: '0', hour: '3', day: '*', month: '*', weekday: '*' }
attribute :retain, kind_of: Integer, required: false
