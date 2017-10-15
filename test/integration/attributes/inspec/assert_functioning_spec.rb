describe command('sysctl -n vm.swappiness') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^19$/) }
end

describe file('/etc/sysctl.d/99-chef-vm.swappiness.conf') do
  before do
  	skip if node['sysctl']['allow_sysctl_conf'] == true
  end

  it { should be_file }
  its(:content) { should match /^vm.swappiness = 19$/ }
end


describe file('/etc/sysctl.conf') do  
  before do
  	skip if node['sysctl']['allow_sysctl_conf'] == false
    skip if node['sysctl']['conf_file'].nil? == false
    skip if node['plaform_family'] == 'freebsd'
    skip if node['plaform_family'] == 'suse' &&  node['platform_version'].to_f < 12.0
  end

  it { should be_file }
  its(:content) { should match /^vm.swappiness = 19$/ }
end
