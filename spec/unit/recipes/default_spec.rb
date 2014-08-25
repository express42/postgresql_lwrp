require 'spec_helper'

describe 'postgresql_lwrp::default' do
  let(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.automatic['memory']['total'] = '1GB'
    end.converge(described_recipe)
  end

  it 'install postgresql-client-9.2 package' do
    expect(chef_run).to install_package('postgresql-client-9.2')
  end

  it 'install libpq-dev package' do
    expect(chef_run).to install_package('libpq-dev')
  end
end
