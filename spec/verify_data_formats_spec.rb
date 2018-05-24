# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'date'

describe 'generating data' do
  it 'encodes hstore data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [1, 'text', { a: 1, b: 'asdf' }]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('3_col_hstore.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes hstore data correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true)
    encoder.add [1, 'text', { a: 1, b: 'asdf' }]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('3_col_hstore.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes hstore with utf8 data correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true)
    encoder.add [{ test: 'Ekström' }]
    encoder.add [{ test: 'Dueñas' }]
    encoder.add [{ 'account_first_name' => 'asdfasdf asñas', 'testtesttesttesttesttestest' => '', 'aasdfasdfasdfasdfasdfasdfasdfasdfasfasfasdfs' => '' }] # needed to verify encoding issue
    encoder.close
    io = encoder.get_io
    existing_data = filedata('hstore_utf8.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes TrueClass data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [true]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('trueclass.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes FalseClass data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [false]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('falseclass.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes array data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [%w(hi jim)]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('array_with_two2.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes string array data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [%w(asdfasdfasdfasdf asdfasdfasdfasdfadsfadf 1123423423423)]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('big_str_array.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes string array with big string int' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [['182749082739172']]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('just_an_array2.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes string array data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [%w(asdfasdfasdfasdf asdfasdfasdfasdfadsfadf)]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('big_str_array2.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes array data from tempfile correctly', pending: 'broken right now' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true)
    encoder.add [1, 'hi', ['hi', 'there', 'rubyist']]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('3_column_array.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes integer array data from tempfile correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true)
    encoder.add [[1, 2, 3]]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('intarray.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes date data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Date.parse('1900-12-03')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('date.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes date data correctly for years > 2000' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Date.parse('2033-01-12')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('date2000.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes date data correctly in the 70s' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Date.parse('1971-12-11')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('date2.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes multiple 2015 dates' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Date.parse('2015-04-08'), nil, Date.parse('2015-04-13')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('dates.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes timestamp data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Time.parse('2013-06-11 15:03:54.62605 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('timestamp.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  require 'time'

  # When this timestamp is converted to float it will incorrectly change the
  # last digit of usecs to and therefore insert the wrong data into the database
  it 'encodes timestamp data correctly without rounding' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Time.parse('2017-07-23 00:02:57.121215 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('timestamp_rounding.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/timestamp_rounding.dat', 'w:ASCII-8BIT') { |out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes dates and times in pg 9.2.4' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Date.parse('2015-04-08'), nil, Time.parse('2015-02-13 16:13:57.732772 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('dates_p924.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes dates and times in pg 9.3.5' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Date.parse('2015-04-08'), nil, Time.parse('2015-02-13 16:13:57.732772 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('dates_pg935.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes timestamp data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Time.parse('2013-06-11 15:03:54.62605 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('timestamp.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes big timestamp data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [Time.parse('2014-12-02 16:01:22.437311 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('timestamp_9.3.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes json hash correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :json })
    encoder.add [{}]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('json.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes json array correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :json })
    encoder.add [[]]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('json_array.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes float correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true)
    encoder.add [Time.parse('2013-06-11 15:03:54.62605 UTC')]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('timestamp.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes float data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    encoder.add [1_234_567.1234567]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('float.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encode float correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true)
    encoder.add [1_234_567.1234567]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('float.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes uuid correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true, column_types: { 0 => :uuid })
    encoder.add ['e876eef5-a116-4a27-b71f-bac4a1dcd20e']
    encoder.close
    io = encoder.get_io
    existing_data = filedata('uuid.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes null uuid correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true, column_types: { 1 => :uuid })
    encoder.add ['before2', nil, nil, 123_423_423]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('empty_uuid.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes uuid correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true, column_types: { 0 => :uuid })
    encoder.add [['6272bd7d-adae-44b7-bba1-dca871c2a6fd', '7dc8431f-fcce-4d4d-86f3-6857cba47d38']]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('uuid_array.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes utf8 string correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new
    ekstrom = 'Ekström'
    encoder.add [ekstrom]
    encoder.close
    io = encoder.get_io
    existing_data = filedata('utf8.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    expect(str).to eq existing_data
  end

  it 'encodes bigint as int correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true, column_types: { 0 => :bigint })
    encoder.add [23_372_036_854_775_808, 'test']
    encoder.close
    io = encoder.get_io
    existing_data = filedata('bigint.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  it 'encodes bigint correctly from tempfile' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(use_tempfile: true, column_types: { 0 => :bigint })
    encoder.add %w(23372036854775808 test)
    encoder.close
    io = encoder.get_io
    existing_data = filedata('bigint.dat')
    str = io.read
    expect(io.class.name).to eq 'Tempfile'
    str.force_encoding('ASCII-8BIT')
    # File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end

  # CREATE TABLE test(i4r int4range, i8r int8range, nr numrange, tr tsrange, tzr tstzrange, dr daterange);
  # INSERT INTO test VALUES ('[12, 14)', '[223372033854775802, 223372033854775810)', '[12.5,13.88211]', '[2010-01-01 15:20, 2010-01-01 15:30)', '[2018-05-24 00:00:00+00,)', '[2018-05-24,)');
  # \copy test TO range_test.dat WITH (FORMAT BINARY);
  it 'encodes range data correctly' do
    encoder = ActiveRecordCopy::EncodeForCopy.new(column_types: { 0 => :int4range, 1 => :int8range, 2 => :numrange, 3 => :tsrange, 4 => :tstzrange, 5 => :daterange })
    encoder.add([
      12...14,
      223372033854775802...223372033854775810,
      12.5..13.88211,
      Time.parse('2010-01-01 15:20+00')...Time.parse('2010-01-01 15:30+00'),
      Time.parse('2018-05-24 00:00:00+00')...Float::INFINITY,
      Date.parse('2018-05-24')...Float::INFINITY
    ])
    encoder.close
    io = encoder.get_io
    existing_data = filedata('range_test.dat')
    str = io.read
    expect(io.class.name).to eq 'StringIO'
    str.force_encoding('ASCII-8BIT')
    #File.open('spec/fixtures/output.dat', 'w:ASCII-8BIT') {|out| out.write(str) }
    expect(str).to eq existing_data
  end
end
