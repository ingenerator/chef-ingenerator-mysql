require 'spec_helper'
require_relative '../../libraries/helper.rb'

describe Ingenerator::Mysql::Helpers do
  let (:my_recipe) { Class.new { extend Ingenerator::Mysql::Helpers } }
  let (:node)      { {} }

  before :example do
    allow(my_recipe).to receive(:node).and_return node
  end

  describe 'root_connection_details' do

    context 'by default' do
      let (:node) { { 'mysql' => { 'default_server_socket' => '/var/run/mysqld/mysqld.sock' } } }
      it 'provides hash with connection details for local socket and socket_auth' do
        expect(my_recipe.mysql_root_connection).to eq(username: 'root',
                                                      socket: '/var/run/mysqld/mysqld.sock')
      end
    end
  end
end
