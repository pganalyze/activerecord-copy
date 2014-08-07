class TempBuffer
  def initialize
    @st = "".force_encoding("ASCII-8BIT")
  end
  def size 
    @st.bytesize
  end

  def write(st)

    @st << st.force_encoding("ASCII-8BIT")
  end
  def rewind

  end
  def reopen
    @st = ""
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
end