require 'spec_helper'

describe 'ingenerator-mysql::app_db' do
  let (:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it "does nothing in the recipe" do
   chef_run.resource_collection.should be_empty
  end

  context "with its attributes" do
    it "adds php5-mysql to the list of extensions the php cookbook should install" do
      chef_run.node['php']['module_packages']['php5-mysql'].should be true
    end

    context "with a project name" do
      let (:chef_run) do
        ChefSpec::Runner.new do |node|
          node.set['project']['name'] = 'someproject'
        end.converge(described_recipe)
      end

      it "sets the schema name to the project name" do
        chef_run.node['project']['services']['db']['schema'].should eq('someproject')
      end

      it "sets the application user to the project name" do
        chef_run.node['project']['services']['db']['user'].should eq('someproject')
      end

      it "sets the application password to the project name" do
        chef_run.node['project']['services']['db']['password'].should eq('someproject')
      end
    end

    context "with no project name" do
      it "sets the schema name to ingenerator" do
        chef_run.node['project']['services']['db']['schema'].should eq('ingenerator')
      end

      it "sets the application user to ingenerator" do
        chef_run.node['project']['services']['db']['user'].should eq('ingenerator')
      end

      it "sets the application password to ingenerator" do
        chef_run.node['project']['services']['db']['password'].should eq('ingenerator')
      end
    end

  end

end
