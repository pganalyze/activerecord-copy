require 'json'
require 'active_record'

require 'activerecord-copy/version'
require 'activerecord-copy/constants'
require 'activerecord-copy/exception'
require 'activerecord-copy/temp_buffer'
require 'activerecord-copy/encode_for_copy'
require 'activerecord-copy/column_helper'

module ActiveRecordCopy
  module CopyFromClient
    extend ActiveSupport::Concern

    class_methods do
      def copy_from_client(columns, table_name: nil, &block)
        table_name ||= quoted_table_name
        connection = self.connection.raw_connection
        column_types = columns.map do |c|
          column = self.columns_hash[c.to_s]
          raise format('Could not find column %s on %s', c, self.table_name) if column.nil?
          ColumnHelper.find_column_type(column)
        end
        sql = %{COPY #{table_name}("#{columns.join('","')}") FROM STDIN BINARY}
        encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: column_types, connection: connection)
        connection.copy_data(sql)  do
          encoder.process(&block)
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecordCopy::CopyFromClient)
