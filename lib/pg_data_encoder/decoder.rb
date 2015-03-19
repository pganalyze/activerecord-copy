require 'tempfile'
require 'stringio'
module PgDataEncoder

  class Decoder
    def initialize(options = {})
      @options = options
      @closed = false
      if options[:column_types].kind_of?(Array)
        map = {}
        options[:column_types].each_with_index {|c, i|
          map[i] = c
        }
        options[:column_types] = map
      else
        options[:column_types] ||= {}
      end
      @io = nil
    end

    def read_line
      return nil if @closed
      setup_io if !@io
      row = []
      bytes = @io.read(2)
      #p bytes
      column_count = bytes.unpack("n").first
      if column_count == 65535
        @closed = true
        return nil
      end
      #@io.write([row.size].pack("n"))
      0.upto(column_count - 1).each {|index|
        field = decode_field(@io)
        if field == nil
          row[index] = field 
        elsif @options[:column_types][index]
          row[index] = map_field(field, @options[:column_types][index])
        else
          row[index] = field
        end
      }
      row
    end

    def each
      loop do
        result = read_line
        if result
          yield result
        else
          break
        end

        if @closed
          break
        end
      end
    end


    private

    def setup_io
      if @options[:file]
        @io = File.open(@options[:file], "r:ASCII-8BIT")
      elsif !@options[:io].nil?
        @io = @options[:io]  
      else
        raise "NO io present"
      end
      header = "PGCOPY\n\377\r\n\0".force_encoding("ASCII-8BIT")
      result = @io.read(header.bytesize)
       if result != header
        raise "invalid format"
      end
     #p @io.read(10)

      @io.read(2)  #blank
      @io.read(6)  #blank
    end

    def decode_field(io)

      bytes = io.read(4)
      
      if bytes == "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
        return nil
      else
        io.read(bytes.unpack("N").first)
      end
    end

    def map_field(data, type)
      #p [type, data]

      case type
      when :int, :integer
        data.unpack("N").first
      when :bytea
        data
      when :bigint
        data.unpack("Q>").first
      when :float, :double
        data.unpack("G").first
      when :boolean
        v = data.unpack("C").first
        v == 1
      when :string, :text, :character
        data.force_encoding("UTF-8")
      when :json
        JSON.load(data)
      when :uuid
        r = data.unpack('H*').first
        "#{r[0..7]}-#{r[8..11]}-#{r[12..15]}-#{r[16..19]}-#{r[20..-1]}"
      when :uuid_raw
        r = data.unpack('H*').first
      when :array, :"integer[]", :"uuid[]", :"character[]"
        io = StringIO.new(data)
        io.read(4)  #unknown
        io.read(4)  #unknown
        atype = io.read(4).unpack("N").first  #string type?
        if io.pos == io.size
          return []
        end
        size = io.read(4).unpack("N").first
        io.read(4) # should be 1 for dimension
        #p [atype, size]
        #p data
        case atype
        when 2950 #uuid
          0.upto(size - 1).map {|i|
            io.read(4) # size
            r = io.read(16).unpack("H*").first
            "#{r[0..7]}-#{r[8..11]}-#{r[12..15]}-#{r[16..19]}-#{r[20..-1]}"
          }
        when 1043 #string
          0.upto(size - 1).map {|i|
            size = io.read(4).unpack("N").first
            io.read(size)
          }
        when 23 #int
          0.upto(size - 1).map {|i|
            size = io.read(4).unpack("N").first
            bytes = io.read(size)
            bytes.unpack("N").first
          }
        else
          raise "Unsupported Array type #{atype}"
        end
      when :hstore, :hash
        io = StringIO.new(data)
        fields = io.read(4).unpack("N").first
        h = {}

        0.upto(fields - 1).each {|i|
          key_size = io.read(4).unpack("N").first
          key = io.read(key_size).force_encoding("UTF-8")
          value_size = io.read(4).unpack("N").first
          if value_size == 4294967295 # nil  "\xFF\xFF\xFF\xFF"
            value = nil
          else
            value = io.read(value_size)
            value = value.force_encoding("UTF-8") if value.present?
          end
          h[key] = value
          #p h
        }
        raise "remaining hstore bytes!" if io.pos != io.size
        h
      when :time, :timestamp
        d = data.unpack("L!>").first
        Time.at((d + POSTGRES_EPOCH_TIME) / 1_000_000.0).utc
      when :date
        # couldn't find another way to get signed network byte order
        m = 0b0111_1111_1111_1111_1111_1111_1111_1111
        d = data.unpack("N").first
        if data.bytes[0] & 0b1000_0000 > 0 # negative number
          d = (d & m) - m - 1
        end

        #p [data, d, Date.jd(d + Date.new(2000,1,1).jd)]
        Date.jd(d + Date.new(2000,1,1).jd)
      else
        raise "Unsupported format #{type}"
      end
    end

  end
end
