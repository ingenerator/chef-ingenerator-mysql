require 'spec_helper'

describe 'ingenerator-mysql::local_admins' do
  let (:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['project']['services']['db']['schema'] = 'app-db'
    end
  end

  let (:chef_run)         { chef_runner.converge described_recipe }
  let (:node_environment) { :production }

  before(:each) do
    allow_any_instance_of(Chef::Node).to receive(:node_environment).and_return(node_environment)
  end
  context 'by default' do
    it 'does not provision any users' do
      expect(chef_run.resource_collection).to be_empty
    end
  end

  context 'when admin users are populated in node attributes' do
    it 'provisions each user whose create flag is true' do
      chef_runner.node.default['mysql']['local_admins']['craig']['create'] = true
      chef_runner.node.default['mysql']['local_admins']['paul']['create'] = true

      expect(chef_run).to create_mysql_local_admin('craig')
      expect(chef_run).to create_mysql_local_admin('paul')
    end

    it 'does not provision users with create flag false or missing' do
      chef_runner.node.default['mysql']['local_admins']['john']['junk'] = 'irrelevant'
      chef_runner.node.default['mysql']['local_admins']['paul']['create'] = false

      expect(chef_run).to_not create_mysql_local_admin('john')
      expect(chef_run).to_not create_mysql_local_admin('paul')
    end

    it 'sets the default database to the application schema by default' do
      chef_runner.node.default['mysql']['local_admins']['phil']['create'] = true
      expect(chef_run).to create_mysql_local_admin('phil').with(
        default_database: 'app-db'
      )
    end

    it 'sets the default database to any value specified for the user' do
      chef_runner.node.default['mysql']['local_admins']['phil']['create'] = true
      chef_runner.node.default['mysql']['local_admins']['phil']['default_database'] = 'my-db'
      expect(chef_run).to create_mysql_local_admin('phil').with(
        default_database: 'my-db'
      )
    end

    it 'assigns default privileges if none specified' do
      chef_runner.node.default['mysql']['local_admins']['billy']['create'] = true

      expect(chef_run).to create_mysql_local_admin('billy').with(
        privileges: Ingenerator::Mysql::DEFAULT_ADMIN_PRIVS
      )
    end

    it 'assigns custom privileges if specified' do
      chef_runner.node.default['mysql']['local_admins']['billy']['create'] = true
      chef_runner.node.default['mysql']['local_admins']['billy']['privileges'] = ['USAGE']

      expect(chef_run).to create_mysql_local_admin('billy').with(
        privileges: ['USAGE']
      )
    end
  end

  context 'when running in local development environment' do
    let (:node_environment) { :localdev }

    it 'provisions a local admin with full permissions for the vagrant user' do
      expect(chef_run).to create_mysql_local_admin('vagrant').with(
        privileges: [:all]
      )
    end

    it 'does not provision a vagrant user if disabled' do
      chef_runner.node.override['mysql']['local_admins']['vagrant']['create'] = false
      expect(chef_run).to_not create_mysql_local_admin('vagrant')
    end
  end
end
