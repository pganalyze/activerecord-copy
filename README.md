# PgDataEncoder

Creates a binary data file that can be imported into postgres's copy from command

Works well in collaboration with the postgres-copy gem

    https://github.com/diogob/postgres-copy

With it you can make a bulk insert like this

    encoder = PgDataEncoder::EncodeForCopy.new
    encoder.add [1, "test", "first"]
    encoder.add [2, "test2", "second"]

    Product.pg_copy_from(encoder.get_io, :format => :binary, :columns => [:id, :name, :desc])

## Try it out yourself,   in the examples folder there is a simple test

on my i3 box with an ssd drive I can get 270,000 inserts a second with an hstore and indexes

NOTE: Only a few of the many data types are supported.  check below for more details

## Installation

Add this line to your application's Gemfile:

    gem 'pg_data_encoder'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pg_data_encoder

## Usage

    pg = PgDataEncoder::EncodeForCopy.new
    pg.add([1,2,3,4,"text"])
    io = pg.get_io

For large imports you can use the use_tempfile => true option to enable Tempfile usage.   otherwise it uses StringIO

    pg = PgDataEncoder::EncodeForCopy.new(use_tempfile: true)
    pg.add([1,2,3,4,"text"])
    io = pg.get_io

    pg.remove  # to delete your file

## Notes


Columns must line up on the incoming table.   if they don't you need to filter the copy to not need them

    COPY table_name FROM STDIN BINARY

or

    COPY table_name(field1, field2) FROM STDIN BINARY



## Added type support

  Currently it supports Integers, Strings, Hstore, Floats (double precision), Timestamp.

## Contributing



1. Fork it
2. Create your feature branch (`git checkout -b feature/new_feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/new_feature`)
5. Create new Pull Request
