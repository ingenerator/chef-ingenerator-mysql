require 'spec_helper'

describe 'ingenerator-mysql::server' do
  let (:chef_run) { ChefSpec::Runner.new(platform:'ubuntu', version:'12.04').converge described_recipe }

  before do
    # stub guards used by the included recipes
    stub_command("\"/usr/bin/mysql\" -u root -e 'show databases;'").and_return(true)

    # mysql cookbook adds a *lot* of warnings to the log
    allow(Chef::Log).to receive(:warn)
  end

  it "installs the mysql server" do
    expect(chef_run).to include_recipe "mysql::server"
  end

  it "includes the database recipe to load chef helpers and mysql client" do
    expect(chef_run).to include_recipe "database::mysql"
  end

  it "manages the root user via the ingenerator-mysql::root_user recipe" do
    expect(chef_run).to include_recipe "ingenerator-mysql::root_user"
  end

  it "manages the application database via the ingenerator-mysql::app_db_server recipe" do
    expect(chef_run).to include_recipe "ingenerator-mysql::app_db_server"
  end

  it "removes anonymous users" do
    expect(chef_run.node['mysql']['remove_anonymous_users']).to be true
  end

  context "when running outside vagrant" do
    it "binds to 127.0.0.1 by default to prevent external connections" do
      # most of our projects are single-host, so should set separately
      expect(chef_run.node['mysql']['bind_address']).to eq('127.0.0.1')
    end
  end

  context "when running under vagrant" do
    it "binds to 0.0.0.0" do
      expect(chef_run.node['mysql']['bind_address']).to eq('127.0.0.1')
    end
  end

end
