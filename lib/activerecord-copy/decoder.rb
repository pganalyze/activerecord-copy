require 'tempfile'
require 'stringio'

module ActiveRecordCopy
  class Decoder
    def initialize(options = {})
      @options = options
      @closed = false
      if options[:column_types].is_a?(Array)
        map = {}
        options[:column_types].each_with_index do |c, i|
          map[i] = c
        end
        options[:column_types] = map
      else
        options[:column_types] ||= {}
      end
      @io = nil
    end

    def read_line
      return nil if @closed
      setup_io unless @io
      row = []
      bytes = @io.read(2)
      # p bytes
      column_count = bytes.unpack(PACKED_UINT_16).first
      if column_count == 65_535
        @closed = true
        return nil
      end
      # @io.write([row.size].pack(PACKED_UINT_32))
      0.upto(column_count - 1).each do |index|
        field = decode_field(@io)
        row[index] = if field.nil?
                       field
                     elsif @options[:column_types][index]
                       map_field(field, @options[:column_types][index])
                     else
                       field
                     end
      end
      row
    end

    def each
      loop do
        result = read_line
        break unless result
        yield result
        break if @closed
      end
    end

    private

    def setup_io
      if @options[:file]
        @io = File.open(@options[:file], 'r:' + ASCII_8BIT_ENCODING)
      elsif !@options[:io].nil?
        @io = @options[:io]
      else
        raise 'NO io present'
      end
      header = "PGCOPY\n\377\r\n\0".force_encoding(ASCII_8BIT_ENCODING)
      result = @io.read(header.bytesize)
      raise 'invalid format' if result != header
      # p @io.read(10)

      @io.read(2) # blank
      @io.read(6) # blank
    end

    def decode_field(io)
      bytes = io.read(4)

      if bytes == "\xFF\xFF\xFF\xFF".force_encoding(ASCII_8BIT_ENCODING)
        return nil
      else
        io.read(bytes.unpack(PACKED_UINT_32).first)
      end
    end

    def map_field(data, type)
      # p [type, data]

      case type
      when :int, :integer
        data.unpack(PACKED_UINT_32).first
      when :bytea
        data
      when :bigint
        data.unpack(PACKED_UINT_64).first
      when :float, :double
        data.unpack(PACKED_FLOAT_64).first
      when :boolean
        v = data.unpack(PACKED_UINT_8).first
        v == 1
      when :string, :text, :character
        data.force_encoding(UTF_8_ENCODING)
      when :json
        JSON.load(data)
      when :uuid
        r = data.unpack('H*').first
        "#{r[0..7]}-#{r[8..11]}-#{r[12..15]}-#{r[16..19]}-#{r[20..-1]}"
      when :uuid_raw
        r = data.unpack('H*').first
      when :array, :"integer[]", :"uuid[]", :"character[]"
        io = StringIO.new(data)
        io.read(4) # unknown
        io.read(4) # unknown
        atype_raw = io.read(4)
        return [] if atype_raw.nil?
        atype = atype_raw.unpack(PACKED_UINT_32).first # string type?
        return [] if io.pos == io.size
        size = io.read(4).unpack(PACKED_UINT_32).first
        io.read(4) # should be 1 for dimension
        # p [atype, size]
        # p data
        case atype
        when UUID_TYPE_OID
          0.upto(size - 1).map do
            io.read(4) # size
            r = io.read(16).unpack(PACKED_HEX_STRING).first
            "#{r[0..7]}-#{r[8..11]}-#{r[12..15]}-#{r[16..19]}-#{r[20..-1]}"
          end
        when TEXT_TYPE_OID, VARCHAR_TYPE_OID
          0.upto(size - 1).map do
            size = io.read(4).unpack(PACKED_UINT_32).first
            io.read(size)
          end
        when INT_TYPE_OID
          0.upto(size - 1).map do
            size = io.read(4).unpack(PACKED_UINT_32).first
            bytes = io.read(size)
            bytes.unpack(PACKED_UINT_32).first
          end
        else
          raise "Unsupported Array type #{atype}"
        end
      when :hstore, :hash
        io = StringIO.new(data)
        fields = io.read(4).unpack(PACKED_UINT_32).first
        h = {}

        0.upto(fields - 1).each do
          key_size = io.read(4).unpack(PACKED_UINT_32).first
          key = io.read(key_size).force_encoding("UTF-8")
          value_size = io.read(4).unpack(PACKED_UINT_32).first
          if value_size == 4294967295 # nil  "\xFF\xFF\xFF\xFF"
            value = nil
          else
            value = io.read(value_size)
            value = value.force_encoding("UTF-8") if !value.nil?
          end
          h[key] = value
        end
        raise "remaining hstore bytes!" if io.pos != io.size
        h
      when :time, :timestamp
        d = data.unpack("L!>").first
        Time.at((d + POSTGRES_EPOCH_TIME) / 1_000_000.0).utc
      when :date
        # couldn't find another way to get signed network byte order
        m = 0b0111_1111_1111_1111_1111_1111_1111_1111
        d = data.unpack(PACKED_UINT_32).first
        d = (d & m) - m - 1 if data.bytes[0] & 0b1000_0000 > 0 # negative number

        # p [data, d, Date.jd(d + Date.new(2000,1,1).jd)]
        Date.jd(d + Date.new(2000, 1, 1).jd)
      else
        raise "Unsupported format #{type}"
      end
    end
  end
end
