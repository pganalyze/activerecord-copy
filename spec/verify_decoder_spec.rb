# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "parsing data" do

  it 'should walk through each line and stop' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("hstore_utf8.dat"), 
      column_types: {0 => :hstore}
    )
    lines = []
    decoder.each do |l|
      lines << l
    end
    lines.should == [
      [{'test' => "Ekström"}],
      [{'test' => "Dueñas"}],
      [{"account_first_name"=>"asdfasdf asñas", "testtesttesttesttesttestest"=>"" , "aasdfasdfasdfasdfasdfasdfasdfasdfasfasfasdfs"=>""}]
    ]
  end
  it 'should handle getting called after running out of data' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("3_col_hstore.dat"), 
      column_types: {0 => :int, 1=> :string, 2 => :hstore}
    )
    r = decoder.read_line
    r.should == [1, "text", {'a' => "1", "b" => "asdf"}]
    decoder.read_line.should == nil
    decoder.read_line.should == nil
    
    
  end
  it 'should encode hstore data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("3_col_hstore.dat"), 
      column_types: {0 => :int, 1=> :string, 2 => :hstore}
    )
    r = decoder.read_line
    r.should == [1, "text", {'a' => "1", "b" => "asdf"}]
    
  end

  it 'should return nil if past data' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("3_col_hstore.dat"), 
      column_types: {0 => :int, 1=> :string, 2 => :hstore}
    )
    r = decoder.read_line
    r.should == [1, "text", {'a' => "1", "b" => "asdf"}]
    r = decoder.read_line
    r.should == nil
  end

  it 'should encode hstore with utf8 data correctly from tempfile' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("hstore_utf8.dat"), 
      column_types: {0 => :hstore}
    )
    r = decoder.read_line
    r.should == [{'test' => "Ekström"}]
    r = decoder.read_line
    r.should == [{'test' => "Dueñas"}]
    r = decoder.read_line
    r.should == [{"account_first_name"=>"asdfasdf asñas", "testtesttesttesttesttestest"=>"" , "aasdfasdfasdfasdfasdfasdfasdfasdfasfasfasdfs"=>""}]

  end

  it 'should encode TrueClass data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("trueclass.dat"), 
      column_types: {0 => :boolean}
    )
    r = decoder.read_line
    r.should == [true]
  end

  it 'should encode FalseClass data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("falseclass.dat"), 
      column_types: {0 => :boolean}
    )
    r = decoder.read_line
    r.should == [false]
  end

  it 'should encode array data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("array_with_two2.dat"), 
      column_types: {0 => :array}
    )
    r = decoder.read_line
    r.should == [["hi", "jim"]]
   
  end

  it 'should encode string array data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("big_str_array.dat"), 
      column_types: {0 => :array}
    )
    r = decoder.read_line
    r.should == [['asdfasdfasdfasdf', 'asdfasdfasdfasdfadsfadf', '1123423423423']]

  end

  it 'should encode string array with big string int' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("just_an_array2.dat"), 
      column_types: {0 => :array}
    )
    r = decoder.read_line
    r.should == [["182749082739172"]]

  end

  it 'should encode string array data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("big_str_array2.dat"), 
      column_types: {0 => :array}
    )
    r = decoder.read_line
    r.should == [['asdfasdfasdfasdf', 'asdfasdfasdfasdfadsfadf']]

  end

  #it 'should encode array data from tempfile correctly' do
  #  encoder = PgDataEncoder::EncodeForCopy.new(:use_tempfile => true)
  #  encoder.add [1, "hi", ["hi", "there", "rubyist"]]
  #  encoder.close
  #  io = encoder.get_io
  #  existing_data = filedata("3_column_array.dat")
  #  str = io.read_line
  #  io.class.name.should == "Tempfile"
  #  str.force_encoding("ASCII-8BIT")
  #  str.should == existing_data
  #end

  it 'should encode integer array data from tempfile correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("intarray.dat"), 
      column_types: {0 => :array}
    )
    r = decoder.read_line
    r.should == [[1,2,3]]
  end

  it 'should encode old date data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("date.dat"), 
      column_types: {0 => :date}
    )
    r = decoder.read_line
    r.should == [Date.parse("1900-12-03")]
    
  end

  it 'should encode date data correctly for years > 2000' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("date2000.dat"), 
      column_types: {0 => :date}
    )
    r = decoder.read_line
    r.should == [Date.parse("2033-01-12")]
  
  end

  it 'should encode date data correctly in the 70s' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("date2.dat"), 
      column_types: {0 => :date}
    )
    r = decoder.read_line
    r.should == [Date.parse("1971-12-11")]
  
  end

  it 'should encode multiple 2015 dates' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("dates.dat"), 
      column_types: {0 => :date, 1 => :date, 2 => :date}
    )
    r = decoder.read_line
    r.should == [Date.parse("2015-04-08"), nil, Date.parse("2015-04-13")]
  
  end

  it 'should encode timestamp data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("timestamp.dat"), 
      column_types: {0 => :time}
    )
    r = decoder.read_line
    r.map(&:to_f).should == [Time.parse("2013-06-11 15:03:54.62605 UTC")].map(&:to_f)
  
  end

  it 'should encode dates and times in pg 9.2.4' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("dates_p924.dat"), 
      column_types: {0 => :date, 2 => :time}
    )
    r = decoder.read_line
    r.map {|f| f.kind_of?(Time) ? f.to_f : f}.should == [Date.parse('2015-04-08'), nil,  Time.parse("2015-02-13 16:13:57.732772 UTC")].map {|f| f.kind_of?(Time) ? f.to_f : f}
  
  end

  it 'should encode dates and times in pg 9.3.5' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("dates_pg935.dat"), 
      column_types: {0 => :date, 2 => :time}
    )
    r = decoder.read_line
    r.map {|f| f.kind_of?(Time) ? f.to_f : f}.should == [Date.parse('2015-04-08'), nil,  Time.parse("2015-02-13 16:13:57.732772 UTC")].map {|f| f.kind_of?(Time) ? f.to_f : f}
  
  end


  it 'should encode big timestamp data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("timestamp_9.3.dat"), 
      column_types: {0 => :time}
    )
    r = decoder.read_line
    r.map {|f| f.kind_of?(Time) ? f.to_f : f}.should == [Time.parse("2014-12-02 16:01:22.437311 UTC")].map {|f| f.kind_of?(Time) ? f.to_f : f}
  
  end

  it 'should encode float data correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("float.dat"), 
      column_types: {0 => :float}
    )
    r = decoder.read_line
    r.should == [1234567.1234567]
  
  end

  it 'should encode uuid correctly from tempfile' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("uuid.dat"), 
      column_types: {0 => :uuid}
    )
    r = decoder.read_line
    r.should == ['e876eef5-a116-4a27-b71f-bac4a1dcd20e']
    
  end

  it 'should encode null uuid correctly from tempfile' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("empty_uuid.dat"), 
      column_types: {0 => :string, 1 => :uuid, 2 => :uuid, 3 => :integer}
    )
    r = decoder.read_line
    r.should == ['before2', nil, nil, 123423423]
    
  end


  it 'should encode uuid correctly from tempfile' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("uuid_array.dat"), 
      column_types: {0 => :array}
    )
    r = decoder.read_line
    r.should == [['6272bd7d-adae-44b7-bba1-dca871c2a6fd', '7dc8431f-fcce-4d4d-86f3-6857cba47d38']]
    
  end


  it 'should encode utf8 string correctly' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("utf8.dat"), 
      column_types: {0 => :string}
    )
    r = decoder.read_line
    r.should == ["Ekström"]
    
  end

  it 'should encode bigint as int correctly from tempfile' do
    decoder = PgDataEncoder::Decoder.new(
      io: fileio("bigint.dat"), 
      column_types: {0 => :bigint, 1 => :string}
    )
    r = decoder.read_line
    r.should == [23372036854775808, 'test']
  end


end
