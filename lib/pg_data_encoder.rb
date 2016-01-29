require "pg_data_encoder/version"

require 'pg_data_encoder/temp_buffer'
require 'pg_data_encoder/encode_for_copy'
require 'pg_data_encoder/decoder'
require 'json'

module PgDataEncoder
  # Your code goes here...
  POSTGRES_EPOCH_TIME = (Time.utc(2000,1,1).to_f * 1_000_000).to_i
end
