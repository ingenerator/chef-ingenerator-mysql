require 'spec_helper'

describe 'ingenerator-mysql::app_db' do
  let (:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it "does nothing in the recipe" do
   expect(chef_run.resource_collection).to be_empty
  end

  context "with its attributes" do
    it "adds php5-mysql to the list of extensions the php cookbook should install" do
      expect(chef_run.node['php']['module_packages']['php5-mysql']).to be true
    end

    context "with a project name" do
      let (:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          node.normal['project']['name'] = 'someproject'
        end.converge(described_recipe)
      end

      it "sets the schema name to the project name" do
        expect(chef_run.node['project']['services']['db']['schema']).to eq('someproject')
      end

      it "sets the application user to the project name" do
        expect(chef_run.node['project']['services']['db']['user']).to eq('someproject')
      end

      it "sets the application password to the project name" do
        expect(chef_run.node['project']['services']['db']['password']).to eq('someproject')
      end
    end

    context "with no project name" do
      it "sets the schema name to ingenerator" do
        expect(chef_run.node['project']['services']['db']['schema']).to eq('ingenerator')
      end

      it "sets the application user to ingenerator" do
        expect(chef_run.node['project']['services']['db']['user']).to eq('ingenerator')
      end

      it "sets the application password to ingenerator" do
        expect(chef_run.node['project']['services']['db']['password']).to eq('ingenerator')
      end
    end

  end

end
