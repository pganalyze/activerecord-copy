# frozen_string_literal: true

require 'tempfile'
require 'stringio'
require 'ipaddr'
require 'active_record'
require_relative 'mac_address'

module ActiveRecordCopy

  class ConnectionWriter
    def initialize(connection)
      @connection = connection
    end

    def flush
      @connection.flush
    end

    def write(buf)
      @connection.sync_put_copy_data(buf)
    end
  end

  class EncodeForCopy
    def initialize(column_types:, connection:)
      @column_types = column_types
      @row_size_encoded = [column_types.size].pack(PACKED_UINT_16)
      @io = ConnectionWriter.new(connection)
    end

    def process(&_block)
      write(@io, "PGCOPY\n\377\r\n\0")
      pack_and_write(@io, [0, 0], PACKED_UINT_32 + PACKED_UINT_32)
      yield self
      @io.flush
    end

    def <<(row)
      self.add(row)
    end

    def add(row)
      fail ArgumentError.new('Empty row added') if row.empty?
      write(@io, @row_size_encoded)
      row.each_with_index do |col, index|
        encode_field(@io, col, index)
      end
    end

    private

    def pack_and_write(io, data, pack_format)
      if io.is_a?(String)
        data.pack(pack_format, buffer: io)
      else
        write(io, data.pack(pack_format))
      end
    end

    def pack_and_write_with_bufsize(io, data, pack_format)
      buf = data.pack(pack_format)
      write_with_bufsize(io, buf)
    end

    # This wrapper is mostly aimed to aid debugging
    def write(io, buf)
      io.write(buf)
    end

    # Pre-allocate very frequent buffer sizes
    BUFSIZE_4 = [4].pack(PACKED_UINT_32)
    BUFSIZE_8 = [8].pack(PACKED_UINT_32)
    BUFSIZE_16 = [16].pack(PACKED_UINT_32)

    def write_with_bufsize(io, buf)
      case buf.bytesize
      when 4
        write(io, BUFSIZE_4)
      when 8
        write(io, BUFSIZE_8)
      when 16
        write(io, BUFSIZE_16)
      else
        pack_and_write(io, [buf.bytesize], PACKED_UINT_32)
      end
      write(io, buf)
    end

    # Primitive types that can also appear in ranges/arrays/etc
    def write_simple_field(io, field, type)
      case type
      when :bigint
        pack_and_write_with_bufsize(io, [field.to_i], PACKED_UINT_64)
      when :integer
        pack_and_write_with_bufsize(io, [field.to_i], PACKED_UINT_32)
      when :smallint
        pack_and_write_with_bufsize(io, [field.to_i], PACKED_UINT_16)
      when :numeric, :decimal
        encode_numeric(io, field)
      when :real
        pack_and_write_with_bufsize(io, [field], PACKED_FLOAT_32)
      when :float
        pack_and_write_with_bufsize(io, [field], PACKED_FLOAT_64)
      when :time
        data = (field - field.beginning_of_day)
        pack_and_write_with_bufsize(io, [data.to_i * 1000000], PACKED_UINT_64)
      when :timestamp, :timestamptz
        data = field.tv_sec * 1_000_000 + field.tv_usec - POSTGRES_EPOCH_TIME
        pack_and_write_with_bufsize(io, [data.to_i], PACKED_UINT_64)
      when :date
        data = field.to_date - Date.new(2000, 1, 1)
        pack_and_write_with_bufsize(io, [data.to_i], PACKED_UINT_32)
      else
        raise Exception, "Unsupported simple type: #{type}"
      end
    end

    NIL_FIELD = [-1].pack(PACKED_UINT_32)

    def encode_field(io, field, index, depth = 0)
      # Nil is an exception in that any kind of field type can have a nil value transmitted
      if field.nil?
        write(io, NIL_FIELD)
        return
      end

      if field.is_a?(Array) && ![:json, :jsonb].include?(@column_types[index])
        encode_array(io, field, index)
        return
      end

      case @column_types[index]
      when :bigint, :integer, :smallint, :numeric, :float, :real, :decimal, :date, :time
        write_simple_field(io, field, @column_types[index])
      when :uuid
        pack_and_write_with_bufsize(io, [field.delete('-')], PACKED_HEX_STRING)
      when :inet, :cidr
        if String === field
          field = IPAddr.new(field)
        end
        encode_ip_addr(io, field)
      when :macaddr
        write_with_bufsize(io, MacAddress.new(field).to_bytes)
      when :binary
        write_with_bufsize(io, field.dup)
      when :json
        field = if field.is_a?(String)
                  field.dup
                else
                  field.to_json
                end
        write_with_bufsize(io, field.encode(UTF_8_ENCODING))
      when :jsonb
        encode_jsonb(io, field)
      when :int4range, :int8range, :numrange, :tsrange, :tstzrange, :daterange
        encode_range(io, field, @column_types[index])
      when :geometry, :geography
        write_with_bufsize(io, field.as_binary)
      else
        encode_based_on_input(io, field, index, depth)
      end
    end

    def encode_based_on_input(io, field, index, depth)
      case field
      when Integer
        pack_and_write_with_bufsize(io, [field], PACKED_UINT_32)
      when Float
        pack_and_write_with_bufsize(io, [field], PACKED_FLOAT_64)
      when true
        pack_and_write_with_bufsize(io, [1], PACKED_UINT_8)
      when false
        pack_and_write_with_bufsize(io, [0], PACKED_UINT_8)
      when String
        write_with_bufsize(io, field.encode(UTF_8_ENCODING))
      when Hash
        raise Exception, "Hash's can't contain hashes" if depth > 0
        hash_io = TempBuffer.new
        pack_and_write(hash_io, [field.size], PACKED_UINT_32)
        field.each_pair do |key, val|
          write_with_bufsize(hash_io, key.to_s.encode(UTF_8_ENCODING))
          encode_field(hash_io, val.nil? ? val : val.to_s, index, depth + 1)
        end
        write_with_bufsize(io, hash_io.string)
      when Time
        write_simple_field(io, field, :timestamp)
      when Date
        write_simple_field(io, field, :date)
      when IPAddr
        encode_ip_addr(io, field)
      when Range
        range_type = case field.begin
                     when Integer
                       :int4range
                     when Float
                       :numrange
                     when Time
                       :tstzrange
                     when Date
                       :daterange
                     else
                       raise Exception, "Unsupported range input type #{field.begin.class.name} for index #{index}"
                     end

        encode_range(io, field, range_type)
      else
        raise Exception, "Unsupported Format: #{field.class.name}"
      end
    end

    def encode_array(io, field, index)
      array_io = TempBuffer.new
      field.compact!
      case field[0]
      when String
        if @column_types[index] == :uuid
          pack_and_write(array_io, [1], PACKED_UINT_32) # unknown
          pack_and_write(array_io, [0], PACKED_UINT_32) # unknown

          pack_and_write(array_io, [UUID_TYPE_OID], PACKED_UINT_32)
          pack_and_write(array_io, [field.size], PACKED_UINT_32)
          pack_and_write(array_io, [1], PACKED_UINT_32) # forcing single dimension array for now

          field.each do |val|
            pack_and_write_with_bufsize(array_io, [val.delete('-')], PACKED_HEX_STRING)
          end
        else
          pack_and_write(array_io, [1], PACKED_UINT_32) # unknown
          pack_and_write(array_io, [0], PACKED_UINT_32) # unknown

          type_oid = @column_types[index] == :text ? TEXT_TYPE_OID : VARCHAR_TYPE_OID
          pack_and_write(array_io, [type_oid], PACKED_UINT_32)
          pack_and_write(array_io, [field.size], PACKED_UINT_32)
          pack_and_write(array_io, [1], PACKED_UINT_32) # forcing single dimension array for now

          field.each do |val|
            write_with_bufsize(array_io, val.to_s.encode(UTF_8_ENCODING))
          end
        end
      when Integer
        pack_and_write(array_io, [1], PACKED_UINT_32) # unknown
        pack_and_write(array_io, [0], PACKED_UINT_32) # unknown

        pack_and_write(array_io, [INT_TYPE_OID], PACKED_UINT_32)
        pack_and_write(array_io, [field.size], PACKED_UINT_32)
        pack_and_write(array_io, [1], PACKED_UINT_32) # forcing single dimension array for now

        field.each do |val|
          pack_and_write_with_bufsize(array_io, [val.to_i], PACKED_UINT_32)
        end
      when nil
        # TODO: Do we need to handle mixed nil and not-nil arrays?
        pack_and_write(io, [-1], PACKED_UINT_32)
        return
      else
        raise Exception, 'Arrays support int or string only'
      end

      write_with_bufsize(io, array_io.string)
    end

    def encode_ip_addr(io, ip_addr)
      if ip_addr.ipv6?
        pack_and_write(io, [4 + 16], PACKED_UINT_32) # Field data size
        pack_and_write(io, [3], PACKED_UINT_8) # Family (PGSQL_AF_INET6)
        pack_and_write(io, [128], PACKED_UINT_8) # Bits
        pack_and_write(io, [0], PACKED_UINT_8) # Is CIDR? => No
        pack_and_write(io, [16], PACKED_UINT_8) # Address length in bytes
      else
        pack_and_write(io, [4 + 4], PACKED_UINT_32) # Field data size
        pack_and_write(io, [2], PACKED_UINT_8) # Family (PGSQL_AF_INET)
        pack_and_write(io, [32], PACKED_UINT_8) # Bits
        pack_and_write(io, [0], PACKED_UINT_8) # Is CIDR? => No
        pack_and_write(io, [4], PACKED_UINT_8) # Address length in bytes
      end
      write(io, ip_addr.hton)
    end

    # From the Postgres source:
    # Binary representation: The first byte is the flags, then the lower bound
    # (if present), then the upper bound (if present).  Each bound is represented
    # by a 4-byte length header and the binary representation of that bound (as
    # returned by a call to the send function for the subtype).
    RANGE_LB_INC = 0x02 # lower bound is inclusive
    RANGE_UB_INC = 0x04 # upper bound is inclusive
    RANGE_LB_INF = 0x08 # lower bound is -infinity
    RANGE_UB_INF = 0x10 # upper bound is +infinity
    def encode_range(io, range, range_type)
      field_data_type = case range_type
                        when :int4range
                          :integer
                        when :int8range
                          :bigint
                        when :numrange
                          :numeric
                        when :tsrange
                          :timestamp
                        when :tstzrange
                          :timestamptz
                        when :daterange
                          :date
                        else
                          raise Exception, "Unsupported range type: #{range_type}"
                        end
      flags = 0
      flags |= RANGE_LB_INC # Ruby ranges always include the lower bound
      flags |= RANGE_UB_INC unless range.exclude_end?
      flags |= RANGE_LB_INF if range.begin.respond_to?(:infinite?) && range.begin.infinite?
      flags |= RANGE_UB_INF if range.end.respond_to?(:infinite?) && range.end.infinite?
      tmp_io = TempBuffer.new
      pack_and_write(tmp_io, [flags], PACKED_UINT_8)
      if range.begin && (!range.begin.respond_to?(:infinite?) || !range.begin.infinite?)
        write_simple_field(tmp_io, range.begin, field_data_type)
      end
      if range.end && (!range.end.respond_to?(:infinite?) || !range.end.infinite?)
        write_simple_field(tmp_io, range.end, field_data_type)
      end
      write_with_bufsize(io, tmp_io.read)
    end

    JSONB_FORMAT_VERSION = 1
    def encode_jsonb(io, field)
      field = if field.is_a?(String)
                field.dup
              else
                field.to_json
              end
      buf = [JSONB_FORMAT_VERSION].pack(PACKED_UINT_8) + field.encode(UTF_8_ENCODING)
      write_with_bufsize(io, buf)
    end

    NUMERIC_NBASE = 10000
    def base10_to_base10000(intval)
      digits = []
      loop do
        newintval = intval / NUMERIC_NBASE
        digits << intval - newintval * NUMERIC_NBASE
        intval = newintval
        break if intval == 0
      end
      digits
    end

    NUMERIC_DEC_DIGITS = 4
    def encode_numeric(io, field)
      float_str = field.abs.to_s
      digits_base10 = float_str.scan(/\d/).map(&:to_i)
      weight_base10 = float_str.index('.')
      sign          = field < 0.0 ? 0x4000 : 0
      dscale        = digits_base10.size - weight_base10

      int_part, frac_part = float_str.split('.')
      frac_part += '0' * (NUMERIC_DEC_DIGITS - frac_part.size % NUMERIC_DEC_DIGITS) # Add trailing zeroes so digit calculations are correct

      digits_before_decpoint = base10_to_base10000(int_part.to_i)
      digits_after_decpoint = base10_to_base10000(frac_part.to_i).reverse

      weight = digits_before_decpoint.size - 1
      digits = digits_before_decpoint + digits_after_decpoint

      pack_and_write(io, [2 * 4 + 2 * digits.size], PACKED_UINT_32) # Field data size
      pack_and_write(io, [digits.size], PACKED_UINT_16) # ndigits
      pack_and_write(io, [weight], PACKED_UINT_16) # weight
      pack_and_write(io, [sign], PACKED_UINT_16) # sign
      pack_and_write(io, [dscale], PACKED_UINT_16) # dscale

      digits.each { |d| pack_and_write(io, [d], PACKED_UINT_16) } # NumericDigits
    end
  end
end
