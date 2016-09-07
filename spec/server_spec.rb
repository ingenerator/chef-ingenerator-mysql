require 'spec_helper'

describe 'ingenerator-mysql::server' do
  let (:has_vagrant_user) { false }
  let (:chef_run) do
    ChefSpec::SoloRunner.new(platform:'ubuntu', version:'12.04') do | node |
      if has_vagrant_user
        node.automatic['etc']['passwd']['vagrant'] = {}
      end
    end.converge described_recipe
  end

  before do
    # stub guards used by the included recipes
    stub_command("\"/usr/bin/mysql\" -u root -e 'show databases;'").and_return(true)

    # mysql cookbook adds a *lot* of warnings to the log
    allow(Chef::Log).to receive(:warn)
  end

  context 'with invalid legacy configuration' do
    let (:chef_run) { ChefSpec::SoloRunner.new }

    %w(server_debian_password server_repl_password allow_remote_root remove_anonymous_users).each do | key |
      it "throws if a #{key} value is still defined in the mysql configuration" do
        chef_run.node.normal['mysql'][key] = 'anything'
        expect { chef_run.converge described_recipe }.to raise_error(ArgumentError)
      end
    end

  end

  it "creates the default mysql service" do
    expect(chef_run).to create_mysql_service 'default'
  end

  it 'assigns the initial root password' do
    expect(chef_run).to create_mysql_service('default').with(
      :initial_root_password => chef_run.node['mysql']['server_root_password']
    )
  end

  it "installs custom configuration" do
    expect(chef_run).to include_recipe "ingenerator-mysql::custom_config"
  end

  it "installs the mysql2_chef_gem to enable database cookbook providers" do
    expect(chef_run).to install_mysql2_chef_gem 'default'
  end

  it "manages the root user via the ingenerator-mysql::root_user recipe" do
    expect(chef_run).to include_recipe "ingenerator-mysql::root_user"
  end

  it "manages the application database via the ingenerator-mysql::app_db_server recipe" do
    expect(chef_run).to include_recipe "ingenerator-mysql::app_db_server"
  end

  context "when running outside vagrant" do
    let (:has_vagrant_user) { false }
       
    it "binds to 127.0.0.1 by default to prevent external connections" do
      # most of our projects are single-host, so should set separately
      expect(chef_run).to create_mysql_service('default').with(
        :bind_address => '127.0.0.1'
      )
    end
  end

  context "when running under vagrant" do
    let (:has_vagrant_user) { true }
    
    it "binds to 0.0.0.0" do
      expect(chef_run).to create_mysql_service('default').with(
        :bind_address => '0.0.0.0'
      )
    end
  end

end
