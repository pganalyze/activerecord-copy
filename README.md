# PgDataEncoder

Creates a binary data file that can be imported into postgres's copy from command


## Installation

Add this line to your application's Gemfile:

    gem 'pg_data_encoder'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pg_data_encoder

## Usage

    pg = PgDataEncoder::CopyBinary.new
    pg.add([1,2,3,4,"text"])
    io = pg.get_io

    pg.remove  # to delete your file

## Notes

* Columns must line up on the incoming table.   if they don't you need to filter the copy to not need them

    COPY table_name FROM STDIN BINARY

or

    COPY table_name(field1, field2) FROM STDIN BINARY



## Added type support

  Currently it supports Integers, Strings, Hstore.

  Help would be appreciated for DateTime, Float, Double, ...
## Contributing



1. Fork it
2. Create your feature branch (`git checkout -b feature/new_feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/new_feature`)
5. Create new Pull Request
