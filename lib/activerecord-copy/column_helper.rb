module ActiveRecordCopy
  class ColumnHelper
    def self.find_column_type(column)
      if column.type == :integer
        case column.limit
        when 8
          :bigint
        when 2
          :smallint
        else
          :integer
        end
      elsif column.sql_type == 'real'
        :real
      else
        column.type
      end
    end
  end
end
