require 'active_record'
require 'postgres-copy'
require 'pg_data_encoder'
require 'benchmark'
# Create a test db before running
# add any needed username, password, port
# install the required gems
#
# gem install postgres-copy pg_data_encoder activerecord --no-ri --no-rdoc


ActiveSupport.on_load :active_record do
  require "postgres-copy/active_record"
end
ActiveRecord::Base.establish_connection(
        :adapter  => "postgresql",
        :host     => "localhost",
        :database => "test"
)
ActiveRecord::Base.connection.execute %{
  SET client_min_messages TO warning;
  DROP TABLE IF EXISTS test_models;
  CREATE TABLE test_models (id serial PRIMARY KEY, data VARCHAR);
}

class TestModel < ActiveRecord::Base
end

encoder = PgDataEncoder::EncodeForCopy.new

puts "Loading data to disk"
puts Benchmark.measure {
  0.upto(1_000_000).each {|i|
    encoder.add ["test data"]
  }
}
puts "inserting into db"
puts Benchmark.measure {
  TestModel.pg_copy_from(encoder.get_io, :format => :binary, :columns => [:data])
}

encoder.remove
# Results on my i5 with ssd backed postgres server
# 11.7 seconds to generate data file.   3.7 seconds to insert 1,000,000 simple items into a table.
#
# 11.670000   0.010000  11.680000 ( 11.733414)
#  0.030000   0.000000   0.030000 (  3.782371)
