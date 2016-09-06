require 'spec_helper'

describe 'ingenerator-mysql::dev_db' do
  let (:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  context "if the root password is not mysql" do
    it "generates an exception to avoid accidentally running on a live database" do
      chef_run.node.normal['mysql']['server_root_password'] = 'somethingsecure'
      expect { chef_run.converge(described_recipe) }.to raise_error(RuntimeError)
    end
  end

  context "when configured with cookbook file sql filenames" do
    let (:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['mysql']['dev_db']['sql_files'] = {'mycookbook::dev_db/table.sql' => true}
      end.converge(described_recipe)
    end
    let (:local_schema_path) { chef_run.node['mysql']['dev_db']['schema_path'] }
    let (:local_file_path)   { local_schema_path+'/dev_db/table.sql' }
    let (:mysql_command)  { "cat #{local_schema_path}/dev_db/table.sql | mysql -uroot -p#{chef_run.node['mysql']['server_root_password']}" }

    it "ensures the parent directory exists" do
      expect(chef_run).to create_directory(local_schema_path+'/dev_db').with(
        :recursive  => true
	  )
    end

    it "copies the sql files from the right cookbooks to the local path" do
      expect(chef_run).to create_cookbook_file(local_file_path).with(
        :cookbook => 'mycookbook',
        :source   => 'dev_db/table.sql'
      )
    end

    context "by default" do
      it "is set to recreate only on changes" do
        expect(chef_run.node['mysql']['dev_db']['recreate_always']).to be false
      end

      it "prepares an execute command to send the sql file to mysql as root" do
        execute = chef_run.find_resource(:execute, mysql_command)
        expect(execute.action).to eq([:nothing])
      end

      it "notifies the provisioning script to run if the file has changed" do
        cookbook_file = chef_run.find_resource(:cookbook_file, local_file_path)
        expect(cookbook_file).to notify('execute['+mysql_command+']').to(:run).immediately
      end
    end

    context "if mysql.dev_db.recreate_always is set" do
      before (:each) do
        chef_run.node.normal['mysql']['dev_db']['recreate_always'] = true
        chef_run.converge described_recipe
      end

      it "executes the mysql command even if there are no changes" do
        expect(chef_run).to run_execute(mysql_command)
      end

      it "does not define a notification on the cookbook file" do
        cookbook_file = chef_run.find_resource(:cookbook_file, local_file_path)
        expect(cookbook_file).not_to notify('execute['+mysql_command+']').to(:run)
      end
    end

    context "if the RECREATE_DEV_DB environment variable is set" do
      before (:each) do
        ENV['RECREATE_DEV_DB'] = "1"
      end

      it "sets the mysql.dev_db.recreate_always attribute true" do
        expect(chef_run.node['mysql']['dev_db']['recreate_always']).to be true
      end
    end
  end

  context "when files have been disabled by attributes elsewhere" do
    let (:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['mysql']['dev_db']['sql_files'] = {'mycookbook::dev_db/table.sql' => false}
      end.converge(described_recipe)
    end

    it "does not create any directories" do
      expect(chef_run.find_resources(:directory)).to be_empty
    end

    it "does not copy any files" do
      expect(chef_run.find_resources(:cookbook_file)).to be_empty
    end

    it "does not prepare any mysql commands" do
      expect(chef_run.find_resources(:execute)).to be_empty
    end
  end
end
