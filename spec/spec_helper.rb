$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'activerecord-copy'
require 'rgeo'
RSpec.configure do |config|
  config.before(:suite) do
  end
end

def filedata(filename)
  str = nil
  File.open("spec/fixtures/#{filename}", 'r:ASCII-8BIT') do |io|
    str = io.read
  end
  str
end

def fileio(filename)
  File.open("spec/fixtures/#{filename}", 'r:ASCII-8BIT')
end
