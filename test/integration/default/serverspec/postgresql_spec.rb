require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

describe 'Postgresql service' do
  it 'has a running service of postgresql' do
    expect(service('postgresql')).to be_running
  end

  it 'is listening on port 5432' do
    expect(port(5432)).to be_listening
  end
end
