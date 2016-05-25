require 'tempfile'
require 'stringio'
module PgDataEncoder

  class EncodeForCopy
    def initialize(options = {})
      @options = options
      @closed = false
      options[:column_types] ||= {}
      @io = nil
      @buffer = TempBuffer.new
    end

    def add(row)
      setup_io if !@io
      @io.write([row.size].pack("n"))
      row.each_with_index {|col, index|
        encode_field(@buffer, col, index)
        if @buffer.size > 0
          #@buffer.rewind
          @io.write(@buffer.read)
          @buffer.reopen
        end
      }
    end

    def close
      @closed = true
      if @buffer.size > 0
        #@buffer.rewind
        @io.write(@buffer.read)
        @buffer.reopen
      end
      @io.write([-1].pack("n")) rescue raise Exception.new("No rows have been added to the encoder!")
      @io.rewind
    end

    def get_io
      if !@closed
        close
      end
      @io
    end

    def remove
      if @io.kind_of?(Tempfile)
        @io.close
        @io.unlink
      end
    end

    private

    def setup_io
      if @options[:use_tempfile] == true
        @io = Tempfile.new("copy_binary", :encoding => 'ascii-8bit')
        unless @options[:skip_unlink] == true
          @io.unlink
        end
      else
        @io = StringIO.new
      end
      @io.write("PGCOPY\n\377\r\n\0")
      @io.write([0,0].pack("NN"))
    end

    def encode_field(io, field, index, depth=0)

      case field
      when Integer
        if @options[:column_types] && @options[:column_types][index] == :bigint
          io.write([8].pack("N"))
          c = [field].pack('Q>')
          io.write(c)
        else
          buf = [field].pack("N")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        end
      when Float
        if @options[:column_types] && @options[:column_types][index] == :decimal
          encode_numeric(io, field)
        else
          buf = [field].pack("G")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        end
      when true
        buf = [1].pack("C")
        io.write([1].pack("N"))
        io.write(buf)
      when false
        buf = [0].pack("C")
        io.write([1].pack("N"))
        io.write(buf)
      when nil
        io.write([-1].pack("N"))
      when String
        if @options[:column_types] && @options[:column_types][index] == :uuid
          io.write([16].pack("N"))
          c = [field.gsub(/-/, "")].pack('H*')
          io.write(c)
        elsif @options[:column_types] && @options[:column_types][index] == :bigint
          io.write([8].pack("N"))
          c = [field.to_i].pack('Q>')
          io.write(c)
        elsif @options[:column_types] && @options[:column_types][index] == :inet
          encode_ip_addr(io, IPAddr.new(field))
        else
          buf = field.encode("UTF-8")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        end
      when Array
        if @options[:column_types] && @options[:column_types][index] == :json
          buf = field.to_json.encode("UTF-8")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        elsif @options[:column_types] && @options[:column_types][index] == :jsonb
          encode_jsonb(io, field)
        else
          array_io = TempBuffer.new
          field.compact!
          completed = false
          case field[0]
          when String
            if @options[:column_types][index] == :uuid
              array_io.write([1].pack("N"))  # unknown
              array_io.write([0].pack("N"))  # unknown

              array_io.write([2950].pack("N"))  # I think is used to determine string data type
              array_io.write([field.size].pack("N"))
              array_io.write([1].pack("N"))   # forcing single dimension array for now

              field.each_with_index {|val, index|
                array_io.write([16].pack("N"))
                c = [val.gsub(/-/, "")].pack('H*')
                array_io.write(c)

              }
            else
              array_io.write([1].pack("N"))  # unknown
              array_io.write([0].pack("N"))  # unknown

              array_io.write([1043].pack("N"))  # I think is used to determine string data type
              array_io.write([field.size].pack("N"))
              array_io.write([1].pack("N"))   # forcing single dimension array for now

              field.each_with_index {|val, index|
                buf = val.to_s.encode("UTF-8")
                array_io.write([buf.bytesize].pack("N"))
                array_io.write(buf)

              }
            end
          when Integer
            array_io.write([1].pack("N"))  # unknown
            array_io.write([0].pack("N"))  # unknown

            array_io.write([23].pack("N"))  # I think is used to detemine int data type
            array_io.write([field.size].pack("N"))
            array_io.write([1].pack("N"))   # forcing single dimension array for now

            field.each_with_index {|val, index|
              buf = [val.to_i].pack("N")
              array_io.write([buf.bytesize].pack("N"))
              array_io.write(buf)

            }
          when nil
            io.write([-1].pack("N"))
            completed = true
          else
            raise Exception.new("Arrays support int or string only")
          end

          if !completed
            io.write([array_io.pos].pack("N"))
            io.write(array_io.string)
          end
        end
      when Hash
        raise Exception.new("Hash's can't contain hashes") if depth > 0
        if @options[:column_types] && @options[:column_types][index] == :json
          buf = field.to_json.encode("UTF-8")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        elsif @options[:column_types] && @options[:column_types][index] == :jsonb
          encode_jsonb(io, field)
        else
          hash_io = TempBuffer.new

          hash_io.write([field.size].pack("N"))
          field.each_pair {|key,val|
            buf = key.to_s.encode("UTF-8")
            hash_io.write([buf.bytesize].pack("N"))
            hash_io.write(buf.to_s)
            encode_field(hash_io, val.nil? ? val : val.to_s, index, depth + 1)
          }
          io.write([hash_io.pos].pack("N"))  # size of hstore data
          io.write(hash_io.string)
        end
      when Time
        buf = [(field.to_f * 1_000_000 - POSTGRES_EPOCH_TIME).to_i].pack("L!>")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when Date
        buf = [(field - Date.new(2000,1,1)).to_i].pack("N")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when IPAddr
        encode_ip_addr(io, field)
      else
        raise Exception.new("Unsupported Format: #{field.class.name}")
      end
    end

    def encode_ip_addr(io, ip_addr)
      if ip_addr.ipv6?
        io.write([4 + 16].pack("N")) # Field data size
        io.write([3].pack("C")) # Family (PGSQL_AF_INET6)
        io.write([128].pack("C")) # Bits
        io.write([0].pack("C")) # Is CIDR? => No
        io.write([16].pack("C")) # Address length in bytes
      else
        io.write([4 + 4].pack("N")) # Field data size
        io.write([2].pack("C")) # Family (PGSQL_AF_INET)
        io.write([32].pack("C")) # Bits
        io.write([0].pack("C")) # Is CIDR? => No
        io.write([4].pack("C")) # Address length in bytes
      end
      io.write(ip_addr.hton)
    end

    def encode_jsonb(io, field)
      buf = field.to_json.encode("UTF-8")
      io.write([1 + buf.bytesize].pack("N"))
      io.write([1].pack("C")) # JSONB format version 1
      io.write(buf)
    end

    NUMERIC_DEC_DIGITS = 4 # NBASE=10000
    def encode_numeric(io, field)
      float_str = field.to_s
      digits_base10 = float_str.scan(/\d/).map { |s| s.to_i }
      weight_base10 = float_str.index('.')
      sign          = field < 0.0 ? 0x4000 : 0
      dscale        = digits_base10.size - weight_base10

      digits_before_decpoint = digits_base10[0..weight_base10].reverse.each_slice(NUMERIC_DEC_DIGITS).map {|d| d.reverse.map(&:to_s).join.to_i }.reverse
      digits_after_decpoint  = digits_base10[weight_base10..-1].each_slice(NUMERIC_DEC_DIGITS).map {|d| d.map(&:to_s).join.to_i }

      weight = digits_before_decpoint.size - 1
      digits = digits_before_decpoint + digits_after_decpoint

      io.write([2*4 + 2*digits.size].pack("N")) # Field data size
      io.write([digits.size].pack("n")) # ndigits
      io.write([weight].pack("n")) # weight
      io.write([sign].pack("n")) # sign
      io.write([dscale].pack("n")) # dscale

      digits.each { |d| io.write([d].pack("n")) } # NumericDigits
    end

  end
end
