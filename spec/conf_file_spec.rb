require 'spec_helper'

describe 'sysctl::default with conf_file not set in attribute' do
  platforms = {
    'ubuntu' => ['14.04', '16.04'],
    'debian' => ['7.11', '8.8'],
    'fedora' => ['25'],
    'redhat' => ['6.9', '7.3'],
    'centos' => ['6.9', '7.3.1611'],
    'freebsd' => ['10.3', '11.0'],
    'suse' => ['12.2'],
  }

  # Test all generic stuff on all platforms
  platforms.each do |platform, versions|
    versions.each do |version|
      context "on #{platform.capitalize} #{version}" do
        let(:conf_file) do
          '/etc/sysctl.conf.test'
        end

        let(:chef_run) do
          ChefSpec::SoloRunner.new(platform: platform, version: version, step_into: ['sysctl_param']) do |node|
            # node.override['sysctl']['conf_file'] = conf_file   (Using fallback in helper)
            node.override['sysctl']['allow_sysctl_conf'] = true
            node.default['sysctl']['params']['vm']['swappiness'] = 90
            allow_any_instance_of(Chef::Resource).to receive(:shell_out).and_call_original
            allow_any_instance_of(Chef::Resource).to receive(:shell_out).with(/^sysctl -w .*/).and_return(double('Mixlib::ShellOut', error!: false))
          end.converge('sysctl::default')
        end
      end
    end
  end
end