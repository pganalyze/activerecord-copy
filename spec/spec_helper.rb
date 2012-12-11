$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'rspec/autorun'

require 'pg_data_encoder'

RSpec.configure do |config|
  config.before(:suite) do


  end
end

def filedata(filename)
  str = nil
  File.open("spec/fixtures/#{filename}", "r:ASCII-8BIT") {|io|
    str = io.read
  }
  str
end