# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'date'

describe 'generating data' do

  let(:connection) {
    MockConnection::new
  }

  it 'encodes text array data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new column_types: { 0 => :text }, connection: connection
    encoder.process do
      encoder.add [['a']]
    end
    existing_data = read_file('text_array.dat')
    str = connection.string
    expect(str).to eq existing_data
  end

  it 'encodes json hash correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :json }, connection: connection)
    encoder.process do
      encoder.add [{}]
    end
    existing_data = read_file('json.dat')
    str = connection.string
    # open_file('json.dat') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes json array correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :json }, connection: connection)
    encoder.process do
      encoder.add [[]]
    end
    existing_data = read_file('json_array.dat')
    str = connection.string
    # File.open('spec/fixtures/json_array.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes real data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new column_types: { 0 => :real }, connection: connection
    encoder.process do
      encoder.add [1_234.1234]
    end
    existing_data = read_file('real.dat')
    str = connection.string
    # File.open('spec/fixtures/real.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  # CREATE TABLE test(i4r int4range, i8r int8range, nr numrange, tr tsrange, tzr tstzrange, dr daterange);
  # INSERT INTO test VALUES ('[12, 14)', '[223372033854775802, 223372033854775810)', '[12.5,13.88211]', '[2010-01-01 15:20, 2010-01-01 15:30)', '[2018-05-24 00:00:00+00,)', '[2018-05-24,)');
  # \copy test TO range_test.dat WITH (FORMAT BINARY);
  it 'encodes range data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :int4range, 1 => :int8range, 2 => :numrange, 3 => :tsrange, 4 => :tstzrange, 5 => :daterange }, connection: connection)
    encoder.process do
      encoder.add(
        [
          12...14,
          223372033854775802...223372033854775810,
          12.5..13.88211,
          Time.parse('2010-01-01 15:20+00')...Time.parse('2010-01-01 15:30+00'),
          Time.parse('2018-05-24 00:00:00+00')...Float::INFINITY,
          Date.parse('2018-05-24')...Float::INFINITY
        ]
      )
    end
    existing_data = read_file('range_test.dat')
    str = connection.string
    # File.open('spec/fixtures/range_test.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes geometry correctly' do
    factory = RGeo::Geographic.simple_mercator_factory()
    point = factory.point(0, 0)
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :geometry }, connection: connection)
    encoder.process do
      encoder.add([point])
    end

    existing_data = read_file('geometry_test.dat')
    str = connection.string
    # File.open('spec/fixtures/geometry_test.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end
end
