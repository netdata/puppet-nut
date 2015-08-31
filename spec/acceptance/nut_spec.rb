require 'spec_helper_acceptance'

describe 'nut' do

  case fact('osfamily')
  when 'OpenBSD'
    conf_dir = '/etc/nut'
    group    = '_ups'
    service  = 'upsd'
  when 'RedHat'
    conf_dir = '/etc/ups'
    group    = 'nut'
    service  = 'nut-server'
  end

  it 'should work with no errors' do

    pp = <<-EOS
      include ::nut

      ::nut::ups { 'dummy':
        driver => 'dummy-ups',
        port   => 'sua1000i.dev',
      }

      file { '#{conf_dir}/sua1000i.dev':
        ensure => file,
        owner  => 0,
        group  => 0,
        mode   => '0644',
        source => '/root/sua1000i.dev',
        before => ::Nut::Ups['dummy'],
      }

      ::nut::user { 'test':
        password => 'password',
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  describe file("#{conf_dir}/ups.conf") do
    it { should be_file }
    it { should be_mode 640 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) do
      should eq <<-EOS.gsub(/^ +/, '')
        # !!! Managed by Puppet !!!
        [dummy]
        	driver = "dummy-ups"
        	port = "sua1000i.dev"
      EOS
    end
  end

  describe file("#{conf_dir}/upsd.users") do
    it { should be_file }
    it { should be_mode 640 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) do
      should eq <<-EOS.gsub(/^ +/, '')
        # !!! Managed by Puppet !!!
        [test]
        	password = password
      EOS
    end
  end

  describe service(service) do
    it { should be_enabled }
    it { should be_running }
  end

  describe command('upsc dummy') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^ups\.model: Smart-UPS 1000$/ }
  end
end
