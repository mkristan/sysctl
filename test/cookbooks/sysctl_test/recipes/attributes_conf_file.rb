#
# Cookbook Name:: test_sysctl
# Attributes:: default
#
# Copyright 2013-2014, OneHealth Solutions, Inc.
# Copyright 2014, Viverae, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Testing saving the sysctl information to a combined .conf file
node.override['sysctl']['allow_sysctl_conf'] = true
node.save

::Chef::Recipe.send(:include, SysctlCookbook::SysctlHelpers::Param)

coerce_attributes(node['sysctl']['params']).each do |x|
  k, v = x.split('=')
  sysctl_param k do
    value v
  end
end if node.attribute?('sysctl') && node['sysctl'].attribute?('params')