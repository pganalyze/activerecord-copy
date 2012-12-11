require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "generating data" do
  it 'should encode hstore data correctly' do
    encoder = PgDataEncoder::CopyBinary.new
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
    encoder = PgDataEncoder::CopyBinary.new(:use_tempfile => true)
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

end