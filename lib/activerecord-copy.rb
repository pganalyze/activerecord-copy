require 'activerecord-copy/version'

require 'activerecord-copy/constants'
require 'activerecord-copy/exception'
require 'activerecord-copy/temp_buffer'

require 'activerecord-copy/encode_for_copy'
require 'activerecord-copy/decoder'

require 'json'

require 'active_record'

module ActiveRecordCopy
  module CopyFromClient
    extend ActiveSupport::Concern

    class CopyHandler
      def initialize(columns:, model_class:, table_name:)
        @columns      = columns
        @model_class  = model_class
        @connection   = model_class.connection.raw_connection
        @table_name   = table_name
        @column_types = columns.map do |c|
          column = model_class.columns_hash[c.to_s]
          raise format('Could not find column %s on %s', c, model_class.table_name) if column.nil?

          if column.type == :integer
            if column.limit == 8
              :bigint
            elsif column.limit == 2
              :smallint
            else
              :integer
            end
          else
            column.type
          end
        end

        reset
      end

      def <<(row)
        @encoder.add row
      end

      def close
        run_copy
      end

      private

      def run_copy
        io = @encoder.get_io

        @connection.copy_data %{COPY #{@table_name}("#{@columns.join('","')}") FROM STDIN BINARY} do
          begin
            while chunk = io.readpartial(10_240) # rubocop:disable Lint/AssignmentInCondition
              @connection.put_copy_data chunk
            end
          rescue EOFError # rubocop:disable Lint/HandleExceptions
          end
        end

        @encoder.remove
        reset

        nil
      end

      def reset
        @encoder = ActiveRecordCopy::EncodeForCopy.new column_types: @column_types
        @row_count = 0
      end
    end

    class_methods do
      def copy_from_client(columns, table_name: nil, &_block)
        table_name ||= quoted_table_name
        handler = CopyHandler.new(columns: columns, model_class: self, table_name: table_name)
        yield(handler)
        handler.close
        true
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecordCopy::CopyFromClient)
