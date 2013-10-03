require 'tempfile'
require 'stringio'
module PgDataEncoder
  POSTGRES_EPOCH_DATE = (Time.utc(2000,1,1).to_f * 1_000_000).to_i
  class EncodeForCopy
    def initialize(options = {})
      @options = options
      @closed = false
      @io = nil
    end

    def add(row)
      setup_io if !@io
      @io.write([row.size].pack("n"))
      row.each {|col|
        encode_field(@io, col)
      }
    end

    def close
      @closed = true
      @io.write([-1].pack("n"))
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
        @io.unlink
      else
        @io = StringIO.new
      end
      @io.write("PGCOPY\n\377\r\n\0")
      @io.write([0,0].pack("NN"))
    end

    def encode_field(io, field, depth=0)
      case field
      when Integer
        buf = [field].pack("N")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when Float
        buf = [field].pack("G")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when nil
        io.write([-1].pack("N"))
      when String
        buf = field.encode("UTF-8")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when Array
        # Some kind of identifier seems to go here??
        # It starts with a special char and then the same exact pattern:
        # IE: \x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x19
        # In some cases I've seen period, in others !s
        #
        # It also apears that the length of the array _might_ be in two different places??
        # Immediately after the possible identifier you have:
        # \x00\x00\x00\x03
        # 3 being the length of the array. For an array with two element that would be 2 instead.
        #
        io.write([field.size].pack("N"))
        field.each {|val|
          buf = val.to_s.encode("UTF-8")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        }
      when Hash
        raise Exception.new("Hash's can't contain hashes") if depth > 0
        hash_io = StringIO.new
        
        hash_io.write([field.size].pack("N"))
        field.each_pair {|key,val|
          buf = key.to_s.encode("UTF-8")
          hash_io.write([buf.bytesize].pack("N"))
          hash_io.write(buf.to_s)
          encode_field(hash_io, val.nil? ? val : val.to_s, depth + 1)
        }
        io.write([hash_io.pos].pack("N"))  # assumed identifier for hstore column
        io.write(hash_io.string)
      when Time
        buf = [(field.to_f * 1_000_000 - POSTGRES_EPOCH_DATE).to_i].pack("L!>")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      else
        raise Exception.new("Unsupported Format: #{field.class.name}")
      end
    end

  end
end
