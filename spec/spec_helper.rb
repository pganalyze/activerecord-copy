$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'dotenv'
Dotenv.load

require 'rspec'
require 'activerecord-copy'
require 'rgeo'
require "base64"

RSpec.configure do |config|
  config.before(:suite) do
  end
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

  def base64
    Base64.strict_encode64(@io.string)
  end
end
