# CopyPaste from edelight/chef-mongodb.

# The build-essential cookbook was not running during the compile phase, install gcc explicitly for rhel so native
# extensions can be installed
gcc = package 'gcc' do
  action :nothing
  only_if { platform_family?('rhel') }
end
gcc.run_action(:install)

if platform_family?('rhel')
  sasldev_pkg = 'cyrus-sasl-devel'
  package sasldev_pkg do
    action :nothing
  end.run_action(:install)
else
  sasldev_pkg = 'libsasl2-dev'
  bash 'fix_shit' do
    code <<-EOF
      apt-get update
      apt-get install -y build-essential
      apt-get install -y libsasl2-dev
    EOF
  end
end


node['mongodb3']['ruby_gems'].each do |gem, version|
  chef_gem gem do
    compile_time false
    version version
  end
end
