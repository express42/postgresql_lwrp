require 'spec_helper'

describe 'postgresql_lwrp::apt_official_repository' do
  let(:chef_run) { ChefSpec::Runner.new(platform: 'ubuntu', version: '12.04').converge(described_recipe) }

  it 'test' do
    expect(chef_run).to add_apt_repository('pg-repo')
  end
end
