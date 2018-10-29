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
      def initialize(columns:, model_class:, table_name:, send_at_once:)
        @columns      = columns
        @model_class  = model_class
        @connection   = model_class.connection.raw_connection
        @table_name   = table_name
        @send_at_once = send_at_once
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
      end

      def <<(row)
        @encoder.add row
        unless @send_at_once
          @connection.put_copy_data(@encoder.get_intermediate_io)
        end
      end

      def copy(&_block)
        reset

        if @send_at_once
          yield(self)
          run_copy_at_once
          return
        end

        @connection.copy_data(copy_sql) do
          begin
            yield(self)
            @encoder.remove # writes the end marker
          rescue EOFError # rubocop:disable Lint/HandleExceptions
          end
        end
      end

      private

      def copy_sql
        %{COPY #{@table_name}("#{@columns.join('","')}") FROM STDIN BINARY}
      end

      def run_copy_at_once
        io = @encoder.get_io

        @connection.copy_data(copy_sql) do
          begin
            while chunk = io.readpartial(10_240) # rubocop:disable Lint/AssignmentInCondition
              @connection.put_copy_data chunk
            end
          rescue EOFError # rubocop:disable Lint/HandleExceptions
          end
        end

        @encoder.remove

        nil
      end

      def reset
        @encoder = ActiveRecordCopy::EncodeForCopy.new column_types: @column_types
      end
    end

    class_methods do
      def copy_from_client(columns, table_name: nil, send_at_once: false, &block)
        table_name ||= quoted_table_name
        handler = CopyHandler.new(columns: columns, model_class: self, table_name: table_name, send_at_once: send_at_once)
        handler.copy(&block)
        true
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecordCopy::CopyFromClient)
