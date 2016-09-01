module PgDataEncoder
  class TempBuffer
    def initialize
      @st = ''.force_encoding(ASCII_8BIT_ENCODING)
    end

    def size
      @st.bytesize
    end

    def write(st)
      @st << st.dup.force_encoding(ASCII_8BIT_ENCODING)
    end

    def rewind
    end

    def reopen
      @st = ''
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
