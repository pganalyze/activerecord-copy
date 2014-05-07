require 'tempfile'
require 'stringio'
module PgDataEncoder
  POSTGRES_EPOCH_TIME = (Time.utc(2000,1,1).to_f * 1_000_000).to_i

  
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
        buf = [field].pack("N")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when Float
        buf = [field].pack("G")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
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
        else
          buf = field.encode("UTF-8")
          io.write([buf.bytesize].pack("N"))
          io.write(buf)
        end
      when Array
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
      when Hash
        raise Exception.new("Hash's can't contain hashes") if depth > 0
        hash_io = TempBuffer.new
        
        hash_io.write([field.size].pack("N"))
        field.each_pair {|key,val|
          buf = key.to_s.encode("UTF-8")
          hash_io.write([buf.bytesize].pack("N"))
          hash_io.write(buf.to_s)
          encode_field(hash_io, val.nil? ? val : val.to_s, index, depth + 1)
        }
        io.write([hash_io.pos].pack("N"))  # assumed identifier for hstore column
        io.write(hash_io.string)
      when Time
        buf = [(field.to_f * 1_000_000 - POSTGRES_EPOCH_TIME).to_i].pack("L!>")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      when Date
        buf = [(field - Date.new(2000,1,1)).to_i].pack("N")
        io.write([buf.bytesize].pack("N"))
        io.write(buf)
      else
        raise Exception.new("Unsupported Format: #{field.class.name}")
      end
    end

  end
end
