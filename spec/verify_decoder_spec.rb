# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'time'

describe 'parsing data' do
  it 'walks through each line and stop' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('hstore_utf8.dat'),
      column_types: { 0 => :hstore }
    )
    lines = []
    decoder.each do |l|
      lines << l
    end
    expect(lines).to eq [
      [{ 'test' => 'Ekström' }],
      [{ 'test' => 'Dueñas' }],
      [{ 'account_first_name' => 'asdfasdf asñas', 'testtesttesttesttesttestest' => '', 'aasdfasdfasdfasdfasdfasdfasdfasdfasfasfasdfs' => '' }]
    ]
  end

  it 'handles getting called after running out of data' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('3_col_hstore.dat'),
      column_types: { 0 => :int, 1 => :string, 2 => :hstore }
    )
    r = decoder.read_line
    expect(r).to eq [1, 'text', { 'a' => '1', 'b' => 'asdf' }]
    expect(decoder.read_line).to be_nil
    expect(decoder.read_line).to be_nil
  end

  it 'encodes hstore data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('3_col_hstore.dat'),
      column_types: { 0 => :int, 1 => :string, 2 => :hstore }
    )
    r = decoder.read_line
    expect(r).to eq [1, 'text', { 'a' => '1', 'b' => 'asdf' }]
  end

  it 'returns nil if past data' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('3_col_hstore.dat'),
      column_types: { 0 => :int, 1 => :string, 2 => :hstore }
    )
    r = decoder.read_line
    expect(r).to eq [1, 'text', { 'a' => '1', 'b' => 'asdf' }]
    r = decoder.read_line
    expect(r).to eq nil
  end

  it 'encodes hstore with utf8 data correctly from tempfile' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('hstore_utf8.dat'),
      column_types: { 0 => :hstore }
    )
    r = decoder.read_line
    expect(r).to eq [{ 'test' => 'Ekström' }]
    r = decoder.read_line
    expect(r).to eq [{ 'test' => 'Dueñas' }]
    r = decoder.read_line
    expect(r).to eq [{ 'account_first_name' => 'asdfasdf asñas', 'testtesttesttesttesttestest' => '', 'aasdfasdfasdfasdfasdfasdfasdfasdfasfasfasdfs' => '' }]
  end

  it 'encodes TrueClass data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('trueclass.dat'),
      column_types: { 0 => :boolean }
    )
    r = decoder.read_line
    expect(r).to eq [true]
  end

  it 'encodes FalseClass data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('falseclass.dat'),
      column_types: { 0 => :boolean }
    )
    r = decoder.read_line
    expect(r).to eq [false]
  end

  it 'encodes array data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('array_with_two2.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [%w(hi jim)]
  end

  it 'encodes string array data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('big_str_array.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [%w(asdfasdfasdfasdf asdfasdfasdfasdfadsfadf 1123423423423)]
  end

  it 'encodes string array with big string int' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('just_an_array2.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [['182749082739172']]
  end

  it 'encodes string array data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('big_str_array2.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [%w(asdfasdfasdfasdf asdfasdfasdfasdfadsfadf)]
  end

  it 'encodes array data from tempfile correctly', pending: 'broken right now' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('3_column_array.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [1, 'hi', ['hi', 'there', 'rubyist']]
  end

  it 'encodes integer array data from tempfile correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('intarray.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [[1, 2, 3]]
  end

  it 'encodes old date data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('date.dat'),
      column_types: { 0 => :date }
    )
    r = decoder.read_line
    expect(r).to eq [Date.parse('1900-12-03')]
  end

  it 'encodes date data correctly for years > 2000' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('date2000.dat'),
      column_types: { 0 => :date }
    )
    r = decoder.read_line
    expect(r).to eq [Date.parse('2033-01-12')]
  end

  it 'encodes date data correctly in the 70s' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('date2.dat'),
      column_types: { 0 => :date }
    )
    r = decoder.read_line
    expect(r).to eq [Date.parse('1971-12-11')]
  end

  it 'encodes multiple 2015 dates' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('dates.dat'),
      column_types: { 0 => :date, 1 => :date, 2 => :date }
    )
    r = decoder.read_line
    expect(r).to eq [Date.parse('2015-04-08'), nil, Date.parse('2015-04-13')]
  end

  it 'encodes timestamp data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('timestamp.dat'),
      column_types: { 0 => :time }
    )
    r = decoder.read_line
    expect(r.map(&:to_f)).to eq [Time.parse('2013-06-11 15:03:54.62605 UTC')].map(&:to_f)
  end

  it 'encodes dates and times in pg 9.2.4' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('dates_p924.dat'),
      column_types: { 0 => :date, 2 => :time }
    )
    r = decoder.read_line
    expect(r.map { |f| f.is_a?(Time) ? f.to_f : f }).to eq [Date.parse('2015-04-08'), nil, Time.parse('2015-02-13 16:13:57.732772 UTC')].map { |f| f.is_a?(Time) ? f.to_f : f }
  end

  it 'encodes dates and times in pg 9.3.5' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('dates_pg935.dat'),
      column_types: { 0 => :date, 2 => :time }
    )
    r = decoder.read_line
    expect(r.map { |f| f.is_a?(Time) ? f.to_f : f }).to eq [Date.parse('2015-04-08'), nil, Time.parse('2015-02-13 16:13:57.732772 UTC')].map { |f| f.is_a?(Time) ? f.to_f : f }
  end

  it 'encodes big timestamp data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('timestamp_9.3.dat'),
      column_types: { 0 => :time }
    )
    r = decoder.read_line
    expect(r.map { |f| f.is_a?(Time) ? f.to_f : f }).to eq [Time.parse('2014-12-02 16:01:22.437311 UTC')].map { |f| f.is_a?(Time) ? f.to_f : f }
  end

  it 'encodes float data correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('float.dat'),
      column_types: { 0 => :float }
    )
    r = decoder.read_line
    expect(r).to eq [1_234_567.1234567]
  end

  it 'encodes uuid correctly from tempfile' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('uuid.dat'),
      column_types: { 0 => :uuid }
    )
    r = decoder.read_line
    expect(r).to eq ['e876eef5-a116-4a27-b71f-bac4a1dcd20e']
  end

  it 'encodes null uuid correctly from tempfile' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('empty_uuid.dat'),
      column_types: { 0 => :string, 1 => :uuid, 2 => :uuid, 3 => :integer }
    )
    r = decoder.read_line
    expect(r).to eq ['before2', nil, nil, 123_423_423]
  end

  it 'encodes uuid correctly from tempfile' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('uuid_array.dat'),
      column_types: { 0 => :array }
    )
    r = decoder.read_line
    expect(r).to eq [['6272bd7d-adae-44b7-bba1-dca871c2a6fd', '7dc8431f-fcce-4d4d-86f3-6857cba47d38']]
  end

  it 'encodes utf8 string correctly' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('utf8.dat'),
      column_types: { 0 => :string }
    )
    r = decoder.read_line
    expect(r).to eq ['Ekström']
  end

  it 'encodes bigint as int correctly from tempfile' do
    decoder = ActiveRecordCopy::Decoder.new(
      io: fileio('bigint.dat'),
      column_types: { 0 => :bigint, 1 => :string }
    )
    r = decoder.read_line
    expect(r).to eq [23_372_036_854_775_808, 'test']
  end
end
