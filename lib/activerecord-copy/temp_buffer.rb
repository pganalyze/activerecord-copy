module ActiveRecordCopy
  class TempBuffer
    def initialize
      @st = String.new.force_encoding(ASCII_8BIT_ENCODING)
    end

    def size
      @st.bytesize
    end

    def write(st)
      @st << st.force_encoding(ASCII_8BIT_ENCODING)
    end

    def rewind
    end

    def reopen
      @st = ''.force_encoding(ASCII_8BIT_ENCODING)
    end

    def read
      @st
    end

    def pos
      @st.bytesize
    end

    def string
      @st
    end

    def empty?
      @st.empty?
    end
  end
end
