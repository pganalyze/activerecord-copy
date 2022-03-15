require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'multiline hstore' do
  let(:connection) {
    MockConnection::new
  }
  it 'encodes multiline hstore data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: {0 => nil, 1 => nil}, connection: connection)
    encoder.process do
      encoder.add [1, { a: 1, b: 2 }]
      encoder.add [2, { a: 1, b: 3 }]
    end

    existing_data = read_file('multiline_hstore.dat')
    str = connection.string
    # File.open("spec/fixtures/multiline_hstore.dat", "w:ASCII-8BIT") {|out| out.write(str) }
    expect(str).to eq existing_data
  end
end
