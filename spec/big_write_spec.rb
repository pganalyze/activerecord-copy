require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'benchmark'
describe "testing changes with large imports and speed issues" do
  it 'should import lots of data quickly' do
    encoder = PgDataEncoder::EncodeForCopy.new(temp_file: true)
    puts Benchmark.measure {
        0.upto(100_000) {|r|
            encoder.add [1, "text", {a: 1, b: "asdf"}]
        }
    }
    encoder.close
    io = encoder.get_io

  end
end