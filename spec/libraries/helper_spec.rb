require 'spec_helper'
require_relative '../../libraries/helper.rb'

describe Ingenerator::Mysql::Helpers do
  let (:my_recipe) { Class.new { extend Ingenerator::Mysql::Helpers } }
  let (:node)      { {} }

  before :example do
    allow(my_recipe).to receive(:node).and_return node
  end

  describe 'root_connection_details' do
    context 'when no root password is configured' do
      let (:node) { {} }

      it 'raises an exception' do
        expect do
          my_recipe.mysql_root_connection
        end.to raise_exception(ArgumentError)
      end
    end

    context 'when root password is configured' do
      let (:node) { { 'mysql' => { 'server_root_password' => 'foo' } } }

      it 'provides hash with connection details' do
        expect(my_recipe.mysql_root_connection).to eq(host: '127.0.0.1',
                                                      username: 'root',
                                                      password: 'foo')
      end
    end
  end
end
