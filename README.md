# activerecord-copy [ ![](https://img.shields.io/gem/v/activerecord-copy.svg)](https://rubygems.org/gems/activerecord-copy) [ ![](https://img.shields.io/gem/dt/activerecord-copy.svg)](https://rubygems.org/gems/activerecord-copy)

Library to assist using binary COPY into PostgreSQL with activerecord.

Binary copy functionality is based on [pg_data_encoder](https://github.com/pbrumm/pg_data_encoder),
but modified to support additional types, and to prefer column type specifications
over inferred data types.

COPY is the most efficient way to bulk-load data into Postgres, since it doesn't have to wait for network round trips between individual rows (amongst other benefits), and using binary encoding instead of text encoding avoids any processing overhead on the database side when parsing the rows.

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-copy'

## Usage

Once you've included the library in your Gemfile, it will automatically add the `copy_from_client` method to `ActiveRecord::Base`, and therefore to all your model classes. You can use it like this:

```ruby
class MyModel < ApplicationRecord
end

my_data = [
  { field_1: 'abc', field_2: 'def' },
  { field_1: 'foo', field_2: 'bar' },
]

MyModel.copy_from_client [:field_1, :field_2] do |copy|
  my_data.each do |d|
    copy << [d[:field_1], d[:field_2]]
  end
end

MyModel.find_by(field_1: 'abc')
```    

## Authors

* [Lukas Fittl](https://github.com/lfittl)

Credits to [Pete Brumm](https://github.com/pbrumm) who wrote pg_data_encoder and
which this library repurposes.

## LICENSE

Copyright (c) 2018, Lukas Fittl <lukas@fittl.com><br>
activerecord-copy is licensed under the MIT license, see LICENSE file for details.

pg_data_encoder is Copyright (c) 2012, Pete Brumm<br>
pg_data_encoder is included under the terms of the MIT license, see LICENSE file for details.
