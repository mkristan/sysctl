#
# Cookbook:: sysctl
# Resource:: param
#
# Copyright:: 2018, Webb Agile Solutions Ltd.
# Copyright:: 2018, Chef Software Inc.
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
property :key, String, name_property: true
property :ignore_error, [true, false], default: false
property :value, [Array, String, Integer, Float], coerce: proc { |v| coerce_value(v) }, required: true
property :conf_dir, String, default: '/etc/sysctl.d'

def after_created
  raise 'The systctl_param resource requires Linux as it needs sysctl and the systctl.d directory functionality.' unless node['os'] == 'linux'
  raise 'The systctl_param resource does not support SLES releases less than 12 as it requires a systctl.d directory' if platform_family?('suse') && node['platform_version'].to_i < 12
end

def coerce_value(v)
  case v
  when Array
    v.join(' ')
  else
    v.to_s
  end
end

def get_sysctl_value(key)
  o = shell_out("sysctl -n -e #{key}")
  raise 'Unknown sysctl key!' if o.error!
  o.stdout.to_s.tr("\t", ' ').strip
end

load_current_value do
  value get_sysctl_value(key)
  if node.default['sysctl']['backup'][key].empty?
    node.default['sysctl']['backup'][key] = value
  end
end

action :apply do
  converge_if_changed do
    # set it temporarily
    set_sysctl_param(new_resource.key, new_resource.value)

    directory new_resource.conf_dir

    file "#{new_resource.conf_dir}/99-chef-#{new_resource.key}.conf" do
      content "#{new_resource.key} = #{new_resource.value}"
    end

    execute 'sysctl -p' do
      command "sysctl #{'-e ' if new_resource.ignore_error}-p"
      action :run
    end
  end
end

action :remove do
  # only converge the resource if the file actually exists to delete
  if ::File.exist?("#{new_resource.conf_dir}/99-chef-#{new_resource.key}.conf")
    converge_by "removing systctl value #{new_resource.key}" do
      file "#{new_resource.conf_dir}/99-chef-#{new_resource.key}.conf" do
        action :delete
      end

      backup_value = node['sysctl']['backup'][new_resource.key]
      set_sysctl_param(new_resource.key, backup_value) unless backup_value.empty?
      node.rm('sysctl', 'backup', new_resource.key)

      execute 'sysctl -p' do
        command 'sysctl -p'
        action :run
      end
    end
  end
end

action_class do
  def set_sysctl_param(key, value)
    shell_out!("sysctl #{'-e ' if new_resource.ignore_error}-w \"#{key}=#{value}\"")
  end
end
