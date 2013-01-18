#
# Cookbook Name:: postgresql
# Resource:: default
#
# Author:: LLC Express 42 (info@express42.com)
#
# Copyright (C) LLC 2012 Express 42
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

def initialize(*args)
    super
    @action = :create
end

actions :create

attribute :cluster_name, :kind_of => String, :name_attribute => true
attribute :cookbook, :kind_of => String
attribute :databag, :kind_of => String              #, :required => true
attribute :cluster_create_options, :kind_of => Array
attribute :configuration, :kind_of => Hash, :default => {}
attribute :hba_configuration, :kind_of => Array, :default => []
attribute :ident_configuration, :kind_of => Array, :default => []
attribute :initial_files, :kind_of => Array, :default => []
attribute :replication, :kind_of => Hash, :default => {}
