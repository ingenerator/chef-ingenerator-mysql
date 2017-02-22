require 'spec_helper'

describe 'ingenerator-mysql::dev_db' do
  let (:root_password)    { nil }
  let (:node_environment) { :localdev }
  let (:recreate_always)  { nil }
  let (:sql_files)        { {} }

  let (:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['mysql']['server_root_password']      = root_password unless root_password.nil?
      node.normal['mysql']['dev_db']['recreate_always'] = recreate_always unless recreate_always.nil?
      node.normal['mysql']['dev_db']['sql_files']       = sql_files
    end.converge(described_recipe)
  end

  before (:example) do
    allow_any_instance_of(Chef::Node).to receive(:node_environment).and_return(node_environment)
    allow_any_instance_of(Chef::Recipe).to receive(:node_environment).and_return(node_environment)
  end

  context 'if the root password is not mysql' do
    let (:root_password) { 'somethingsecure' }

    it 'generates an exception to avoid accidentally running on a live database' do
      expect { chef_run }.to raise_error(RuntimeError)
    end
  end

  context 'when configured with cookbook file sql filenames' do
    let (:sql_files)         { { 'mycookbook::dev_db/table.sql' => true } }
    let (:local_schema_path) { chef_run.node['mysql']['dev_db']['schema_path'] }
    let (:local_file_path)   { local_schema_path + '/dev_db/table.sql' }
    let (:mysql_command)     { "cat #{local_schema_path}/dev_db/table.sql | mysql -uroot -p#{chef_run.node['mysql']['server_root_password']}" }

    it 'ensures the parent directory exists' do
      expect(chef_run).to create_directory(local_schema_path + '/dev_db').with(
        recursive: true
      )
    end

    it 'copies the sql files from the right cookbooks to the local path' do
      expect(chef_run).to create_cookbook_file(local_file_path).with(
        cookbook: 'mycookbook',
        source: 'dev_db/table.sql'
      )
    end

    context 'by default' do
      context 'in the buildslave environment' do
        let (:node_environment) { :buildslave }

        it 'is set to recreate_always' do
          expect(chef_run.node['mysql']['dev_db']['recreate_always']).to be(true)
        end
      end

      context 'outside the buildslave environment' do
        let (:node_environment) { :localdev }

        context 'without RECREATE_DEV_DB environment variable' do
          it 'is not set to recreate_always' do
            expect(chef_run.node['mysql']['dev_db']['recreate_always']).to be(false)
          end
        end

        context 'when RECREATE_DEV_DB environment variable is set' do
          before (:each) do
            ENV['RECREATE_DEV_DB'] = '1'
          end

          it 'is set to recreate_always' do
            expect(chef_run.node['mysql']['dev_db']['recreate_always']).to be(true)
          end
        end
      end
    end

    context 'when recreate_always is not set' do
      let (:recreate_always) { false }

      it 'prepares but does not run an execute command to send the sql file to mysql as root' do
        execute = chef_run.find_resource(:execute, mysql_command)
        expect(execute.action).to eq([:nothing])
      end

      it 'notifies the provisioning script to run if the file has changed' do
        cookbook_file = chef_run.find_resource(:cookbook_file, local_file_path)
        expect(cookbook_file).to notify('execute[' + mysql_command + ']').to(:run).immediately
      end
    end

    context 'when recreate_always is set' do
      let (:recreate_always) { true }

      it 'executes the mysql command even if there are no changes' do
        expect(chef_run).to run_execute(mysql_command)
      end

      it 'does not define a notification on the cookbook file' do
        cookbook_file = chef_run.find_resource(:cookbook_file, local_file_path)
        expect(cookbook_file).not_to notify('execute[' + mysql_command + ']').to(:run)
      end
    end
  end

  context 'when files have been disabled by attributes elsewhere' do
    let (:sql_files) { { 'mycookbook::dev_db/table.sql' => false } }

    it 'does not create any directories' do
      expect(chef_run.find_resources(:directory)).to be_empty
    end

    it 'does not copy any files' do
      expect(chef_run.find_resources(:cookbook_file)).to be_empty
    end

    it 'does not prepare any mysql commands' do
      expect(chef_run.find_resources(:execute)).to be_empty
    end
  end
end
