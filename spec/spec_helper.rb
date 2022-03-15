$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'dotenv'
Dotenv.load

require 'rspec'
require 'activerecord-copy'
require 'rgeo'

RSpec.configure do |config|
  config.before(:suite) do
  end
end

def read_file(filename)
  File.open("spec/fixtures/#{filename}", 'r:ASCII-8BIT').read
end

def open_file(filename)
  File.open("spec/fixtures/#{filename}", 'r:ASCII-8BIT')
end


class MockConnection
  def initialize
    @io = StringIO.new
    @io.set_encoding('ASCII-8BIT')
  end

  def sync_put_copy_data(buf)
    @io.write(buf)
  end

  def flush
  end

  def string
    @io.string
  end
end
