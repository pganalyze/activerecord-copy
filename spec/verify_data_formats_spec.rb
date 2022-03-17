# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'date'

describe 'generating data' do

  let(:connection) {
    MockConnection::new
  }

  it 'encodes text array data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :text }, connection: connection)
    encoder.process do
      encoder.add [['a']]
    end
    str = connection.base64
    expect(str).to eq "UEdDT1BZCv8NCgAAAAAAAAAAAAABAAAAGQAAAAEAAAAAAAAAGQAAAAEAAAABAAAAAWE="
  end

  it 'encodes json hash correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :json }, connection: connection)
    encoder.process do
      encoder.add [{}]
    end
    str = connection.base64
    puts str
    expect(str).to eq "UEdDT1BZCv8NCgAAAAAAAAAAAAABAAAAAnt9"
  end

  it 'encodes json array correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :json }, connection: connection)
    encoder.process do
      encoder.add [[]]
    end
    str = connection.base64
    expect(str).to eq  "UEdDT1BZCv8NCgAAAAAAAAAAAAABAAAAAltd"
  end

  it 'encodes real data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :real }, connection: connection)
    encoder.process do
      encoder.add [1_234.1234]
      encoder.add [-1_234.1234]
    end
    str = connection.base64
    expect(str).to eq "UEdDT1BZCv8NCgAAAAAAAAAAAAABAAAABESaQ/MAAQAAAATEmkPz"
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
    str = connection.base64
    puts str
    expect(str).to eq "UEdDT1BZCv8NCgAAAAAAAAAAAAAGAAAAEQIAAAAEAAAADAAAAAQAAAAOAAAAGQIAAAAIAxmTrmqrofoAAAAIAxmTrmqrogIAAAAjBgAAAAwAAgAAAAAAAQAME4gAAAAOAAMAAAAAAAUADSJ1A+gAAAAZAgAAAAgAAR8arHoIAAAAAAgAAR8a0D1OAAAAAA0SAAAACAACD+cZ6UAAAAAACRIAAAAEAAAaPg=="
  end

  it 'encodes geometry correctly' do
    factory = RGeo::Geographic.simple_mercator_factory()
    point = factory.point(1, 5)
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :geometry }, connection: connection)
    encoder.process do
      encoder.add([point])
    end
    str = connection.base64
    expect(str).to eq "UEdDT1BZCv8NCgAAAAAAAAAAAAABAAAAFQAAAAABP/AAAAAAAABAFAAAAAAAAA=="
  end

  it 'encodes multiline hstore data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: {0 => nil, 1 => nil}, connection: connection)
    encoder.process do
      encoder.add [1, { a: 1, b: 2 }]
      encoder.add [2, { a: 1, b: 3 }]
    end

    str = connection.base64
    expect(str).to eq "UEdDT1BZCv8NCgAAAAAAAAAAAAACAAAABAAAAAEAAAAYAAAAAgAAAAFhAAAAATEAAAABYgAAAAEyAAIAAAAEAAAAAgAAABgAAAACAAAAAWEAAAABMQAAAAFiAAAAATM="
  end
end
