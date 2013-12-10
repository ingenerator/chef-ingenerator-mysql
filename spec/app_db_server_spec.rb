require 'spec_helper'

describe 'ingenerator-mysql::app_db_server' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }
  let (:root_connection) { {:host => 'localhost', :username => 'root', :password => chef_run.node['mysql']['server_root_password']} }
  let (:default_app_privileges) { ["LOCK TABLES", "DELETE", "INSERT", "SELECT", "UPDATE", "EXECUTE"].sort }

  before (:each) do
    Chef::Log.stub(:warn)
  end

  it "creates a database for the application" do
    chef_run.should create_mysql_database(chef_run.node['project']['services']['db']['schema']).with(
      :connection => root_connection
    )
  end

  it "creates the application database user" do
    chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
      :password   => chef_run.node['project']['services']['db']['password'],
      :connection => root_connection
    )
  end

  context "by default" do
    it "allows the app user to connect from localhost only" do
      chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
        :host  => 'localhost'
      )
    end

    it "grants user-level privileges to the app user" do
      chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
        :privileges => default_app_privileges
      )
    end

    it "only grants privileges on the application schema" do
      chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
        :database_name => chef_run.node['project']['services']['db']['schema']
      )
    end
  end

  context "with project.services.db.connect_anywhere set" do
    let (:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['project']['services']['db']['connect_anywhere'] = true
      end.converge(described_recipe)
    end

    it "allows the app user to connect from any host" do
      chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
        :host  => '%'
      )
    end
  end

  context "with extra permissions in project.services.db.privileges" do
    let (:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['project']['services']['db']['privileges']['DROP'] = true
      end.converge(described_recipe)
    end

    it "grants the app user the additional privileges" do
      custom_privs = default_app_privileges
      custom_privs << 'DROP'
      chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
        :privileges  => custom_privs.sort
      )
    end
  end

  context "with permissions disabled in project.services.db.allowed_operations" do
    let (:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['project']['services']['db']['privileges']['DELETE'] = false
      end.converge(described_recipe)
    end

    it "grants the app user the additional privileges" do
      custom_privs = default_app_privileges
      custom_privs.delete('DELETE')
      chef_run.should grant_mysql_database_user(chef_run.node['project']['services']['db']['user']).with(
        :privileges  => custom_privs.sort
      )
    end
  end

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
