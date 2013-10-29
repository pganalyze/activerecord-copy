require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "generating data" do
  it 'should encode hstore data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [1, "text", {a: 1, b: "asdf"}]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("3_col_hstore.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    #File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    str.should == existing_data
  end

  it 'should encode hstore data correctly from tempfile' do
    encoder = PgDataEncoder::EncodeForCopy.new(:use_tempfile => true)
    encoder.add [1, "text", {a: 1, b: "asdf"}]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("3_col_hstore.dat")
    str = io.read
    io.class.name.should == "Tempfile"
    str.force_encoding("ASCII-8BIT")
    #File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    str.should == existing_data
  end

  it 'should encode TrueClass data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [true]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("trueclass.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode FalseClass data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [false]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("falseclass.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode array data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [["hi", "jim"]]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("array_with_two2.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode string array data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [['asdfasdfasdfasdf', 'asdfasdfasdfasdfadsfadf', '1123423423423']]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("big_str_array.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode string array with big string int' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [["182749082739172"]]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("just_an_array2.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode string array data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [['asdfasdfasdfasdf', 'asdfasdfasdfasdfadsfadf']]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("big_str_array2.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  #it 'should encode array data from tempfile correctly' do
  #  encoder = PgDataEncoder::EncodeForCopy.new(:use_tempfile => true)
  #  encoder.add [1, "hi", ["hi", "there", "rubyist"]]
  #  encoder.close
  #  io = encoder.get_io
  #  existing_data = filedata("3_column_array.dat")
  #  str = io.read
  #  io.class.name.should == "Tempfile"
  #  str.force_encoding("ASCII-8BIT")
  #  str.should == existing_data
  #end

  it 'should encode integer array data from tempfile correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new(:use_tempfile => true)
    encoder.add [[1,2,3]]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("intarray.dat")
    str = io.read
    io.class.name.should == "Tempfile"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode date data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [Date.parse("1900-12-03")]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("date.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode date data correctly for years > 2000' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [Date.parse("2033-01-12")]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("date2000.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode date data correctly in the 70s' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [Date.parse("1971-12-11")]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("date2.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    str.should == existing_data
  end

  it 'should encode timestamp data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [Time.parse("2013-06-11 15:03:54.62605 UTC")]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("timestamp.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    #File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    str.should == existing_data
  end

  it 'should encode float correctly from tempfile' do
    encoder = PgDataEncoder::EncodeForCopy.new(:use_tempfile => true)
    encoder.add [Time.parse("2013-06-11 15:03:54.62605 UTC")]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("timestamp.dat")
    str = io.read
    io.class.name.should == "Tempfile"
    str.force_encoding("ASCII-8BIT")
    #File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    str.should == existing_data
  end

  it 'should encode float data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [1234567.1234567]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("float.dat")
    str = io.read
    io.class.name.should == "StringIO"
    str.force_encoding("ASCII-8BIT")
    #File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    str.should == existing_data
  end

  it 'should encode float correctly from tempfile' do
    encoder = PgDataEncoder::EncodeForCopy.new(:use_tempfile => true)
    encoder.add [1234567.1234567]
    encoder.close
    io = encoder.get_io
    existing_data = filedata("float.dat")
    str = io.read
    io.class.name.should == "Tempfile"
    str.force_encoding("ASCII-8BIT")
    #File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    str.should == existing_data
  end

end
