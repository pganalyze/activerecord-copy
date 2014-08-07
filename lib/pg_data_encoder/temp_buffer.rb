class TempBuffer
  def initialize
    @st = ""
  end
  def size 
    @st.bytesize
  end

  def write(st)
    @st << st
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