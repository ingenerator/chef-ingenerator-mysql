require 'spec_helper'

describe 'ingenerator-mysql::app_db_server' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  before (:each) do
    Chef::Log.stub(:warn)
  end

  it "creates a database for the application" do
    chef_run.should create_mysql_database(chef_run.node['project']['services']['db']['schema']).with(
      :connection => { :host => 'localhost', :username => 'root', :password => chef_run.node['mysql']['server_root_password'] }
    )
  end

  it "creates the application database user"
  it "grants appropriate permissions to the application database user"

  context "when running under vagrant" do
    let (:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['vagrant'] = {}
      end.converge(described_recipe)
    end

    it "does not emit a root password security warning" do
      expect(Chef::Log).not_to receive(:warn).with(
        'Your app db password is not secure and you are not running under vagrant - check your configuration'
      )
      chef_run.converge(described_recipe)
    end

  end

  context "when not under vagrant" do
    it "emits a warning if the root password is 'mysql'" do
      expect(Chef::Log).to receive(:warn).at_least(:once).with(
        'Your app db password is not secure and you are not running under vagrant - check your configuration'
      )
      chef_run.node.set['mysql']['server_root_password'] = 'mysql'
      chef_run.converge(described_recipe)
    end
  end

end
