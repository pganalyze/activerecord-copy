require 'tempfile'
require 'stringio'
require 'ipaddr'

module ActiveRecordCopy
  class IntermediateBuffer
    attr_reader :bytes
    def initialize
      @bytes = ''
    end

    def write(b)
      @bytes += b
    end

    def size
      @bytes.size
    end
  end

  class EncodeForCopy
    def initialize(options = {})
      @options = options
      @closed = false
      @column_types = @options[:column_types] || {}
      @io = nil
      @buffer = TempBuffer.new
    end

    def add(row)
      setup_io unless @io
      @io.write([row.size].pack(PACKED_UINT_16))
      row.each_with_index do |col, index|
        encode_field(@buffer, col, index)
        next if @buffer.empty?
        @io.write(@buffer.read)
        @buffer.reopen
      end
    end

    def close
      @closed = true
      unless @buffer.empty?
        @io.write(@buffer.read)
        @buffer.reopen
      end
      @io.write([-1].pack(PACKED_UINT_16)) rescue raise Exception, 'No rows have been added to the encoder!'
      @io.rewind
    end

    def get_io
      close unless @closed
      @io
    end

    def remove
      return unless @io.is_a?(Tempfile)

      @io.close
      @io.unlink
    end

    private

    def setup_io
      if @options[:use_tempfile] == true
        @io = Tempfile.new('copy_binary', encoding: 'ascii-8bit')
        @io.unlink unless @options[:skip_unlink] == true
      else
        @io = StringIO.new
      end
      @io.write("PGCOPY\n\377\r\n\0")
      @io.write([0, 0].pack(PACKED_UINT_32 + PACKED_UINT_32))
    end

    def write_field(io, buf)
      io.write([buf.bytesize].pack(PACKED_UINT_32))
      io.write(buf)
    end

    # Primitive types that can also appear in ranges/arrays/etc
    def write_simple_field(io, field, type)
      case type
      when :bigint
        buf = [field.to_i].pack(PACKED_UINT_64)
        write_field(io, buf)
      when :integer
        buf = [field.to_i].pack(PACKED_UINT_32)
        write_field(io, buf)
      when :smallint
        buf = [field.to_i].pack(PACKED_UINT_16)
        write_field(io, buf)
      when :numeric
        encode_numeric(io, field)
      when :float
        buf = [field].pack(PACKED_FLOAT_64)
        write_field(io, buf)
      when :timestamp, :timestamptz
        buf = [(field.tv_sec * 1_000_000 + field.tv_usec - POSTGRES_EPOCH_TIME).to_i].pack(PACKED_UINT_64)
        write_field(io, buf)
      when :date
        buf = [(field - Date.new(2000, 1, 1)).to_i].pack(PACKED_UINT_32)
        write_field(io, buf)
      else
        raise Exception, "Unsupported simple type: #{type}"
      end
    end

    def encode_field(io, field, index, depth = 0)
      # Nil is an exception in that any kind of field type can have a nil value transmitted
      if field.nil?
        io.write([-1].pack(PACKED_UINT_32))
        return
      end

      if field.is_a?(Array) && ![:json, :jsonb].include?(@column_types[index])
        encode_array(io, field, index)
        return
      end

      case @column_types[index]
      when :bigint, :integer, :smallint, :numeric, :float
        write_simple_field(io, field, @column_types[index])
      when :uuid
        buf = [field.delete('-')].pack(PACKED_HEX_STRING)
        write_field(io, buf)
      when :inet
        encode_ip_addr(io, IPAddr.new(field))
      when :binary
        write_field(io, field)
      when :json
        buf = field.to_json.encode(UTF_8_ENCODING)
        write_field(io, buf)
      when :jsonb
        encode_jsonb(io, field)
      when :int4range, :int8range, :numrange, :tsrange, :tstzrange, :daterange
        encode_range(io, field, @column_types[index])
      else
        encode_based_on_input(io, field, index, depth)
      end
    end

    def encode_based_on_input(io, field, index, depth)
      case field
      when Integer
        buf = [field].pack(PACKED_UINT_32)
        write_field(io, buf)
      when Float
        buf = [field].pack(PACKED_FLOAT_64)
        write_field(io, buf)
      when true
        buf = [1].pack(PACKED_UINT_8)
        write_field(io, buf)
      when false
        buf = [0].pack(PACKED_UINT_8)
        write_field(io, buf)
      when String
        buf = field.encode(UTF_8_ENCODING)
        write_field(io, buf)
      when Hash
        raise Exception, "Hash's can't contain hashes" if depth > 0
        hash_io = TempBuffer.new
        hash_io.write([field.size].pack(PACKED_UINT_32))
        field.each_pair do |key, val|
          buf = key.to_s.encode(UTF_8_ENCODING)
          write_field(hash_io, buf)
          encode_field(hash_io, val.nil? ? val : val.to_s, index, depth + 1)
        end
        io.write([hash_io.pos].pack(PACKED_UINT_32)) # size of hstore data
        io.write(hash_io.string)
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
      completed = false
      case field[0]
      when String
        if @column_types[index] == :uuid
          array_io.write([1].pack(PACKED_UINT_32)) # unknown
          array_io.write([0].pack(PACKED_UINT_32)) # unknown

          array_io.write([UUID_TYPE_OID].pack(PACKED_UINT_32))
          array_io.write([field.size].pack(PACKED_UINT_32))
          array_io.write([1].pack(PACKED_UINT_32)) # forcing single dimension array for now

          field.each do |val|
            buf = [val.delete('-')].pack(PACKED_HEX_STRING)
            write_field(array_io, buf)
          end
        else
          array_io.write([1].pack(PACKED_UINT_32))  # unknown
          array_io.write([0].pack(PACKED_UINT_32))  # unknown

          array_io.write([VARCHAR_TYPE_OID].pack(PACKED_UINT_32))
          array_io.write([field.size].pack(PACKED_UINT_32))
          array_io.write([1].pack(PACKED_UINT_32)) # forcing single dimension array for now

          field.each do |val|
            buf = val.to_s.encode(UTF_8_ENCODING)
            write_field(array_io, buf)
          end
        end
      when Integer
        array_io.write([1].pack(PACKED_UINT_32)) # unknown
        array_io.write([0].pack(PACKED_UINT_32)) # unknown

        array_io.write([INT_TYPE_OID].pack(PACKED_UINT_32))
        array_io.write([field.size].pack(PACKED_UINT_32))
        array_io.write([1].pack(PACKED_UINT_32)) # forcing single dimension array for now

        field.each do |val|
          buf = [val.to_i].pack(PACKED_UINT_32)
          write_field(array_io, buf)
        end
      when nil
        io.write([-1].pack(PACKED_UINT_32))
        completed = true
      else
        raise Exception, 'Arrays support int or string only'
      end

      unless completed
        io.write([array_io.pos].pack(PACKED_UINT_32))
        io.write(array_io.string)
      end
    end

    def encode_ip_addr(io, ip_addr)
      if ip_addr.ipv6?
        io.write([4 + 16].pack(PACKED_UINT_32)) # Field data size
        io.write([3].pack(PACKED_UINT_8)) # Family (PGSQL_AF_INET6)
        io.write([128].pack(PACKED_UINT_8)) # Bits
        io.write([0].pack(PACKED_UINT_8)) # Is CIDR? => No
        io.write([16].pack(PACKED_UINT_8)) # Address length in bytes
      else
        io.write([4 + 4].pack(PACKED_UINT_32)) # Field data size
        io.write([2].pack(PACKED_UINT_8)) # Family (PGSQL_AF_INET)
        io.write([32].pack(PACKED_UINT_8)) # Bits
        io.write([0].pack(PACKED_UINT_8)) # Is CIDR? => No
        io.write([4].pack(PACKED_UINT_8)) # Address length in bytes
      end
      io.write(ip_addr.hton)
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
      tmp_io = IntermediateBuffer.new
      tmp_io.write([flags].pack(PACKED_UINT_8))
      if range.begin && (!range.begin.respond_to?(:infinite?) || !range.begin.infinite?)
        write_simple_field(tmp_io, range.begin, field_data_type)
      end
      if range.end && (!range.end.respond_to?(:infinite?) || !range.end.infinite?)
        write_simple_field(tmp_io, range.end, field_data_type)
      end
      io.write([tmp_io.size].pack(PACKED_UINT_32))
      io.write(tmp_io.bytes)
    end

    def encode_jsonb(io, field)
      buf = field.to_json.encode(UTF_8_ENCODING)
      io.write([1 + buf.bytesize].pack(PACKED_UINT_32))
      io.write([1].pack(PACKED_UINT_8)) # JSONB format version 1
      io.write(buf)
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
      float_str = field.to_s
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

      io.write([2 * 4 + 2 * digits.size].pack(PACKED_UINT_32)) # Field data size
      io.write([digits.size].pack(PACKED_UINT_16)) # ndigits
      io.write([weight].pack(PACKED_UINT_16)) # weight
      io.write([sign].pack(PACKED_UINT_16)) # sign
      io.write([dscale].pack(PACKED_UINT_16)) # dscale

      digits.each { |d| io.write([d].pack(PACKED_UINT_16)) } # NumericDigits
    end
  end
end
