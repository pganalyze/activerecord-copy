class TempBuffer
  def initialize
    @st = ""
  end
  def size 
    @st.size
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
    @st.size
  end
  def string
    @st
  end
end