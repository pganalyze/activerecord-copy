require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'multiline hstore' do
  it 'encodes multiline hstore data correctly' do
    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [1, { a: 1, b: 2 }]
    encoder.add [2, { a: 1, b: 3 }]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('multiline_hstore.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open("spec/fixtures/output.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    expect(str).to eq existing_data
  end
end
