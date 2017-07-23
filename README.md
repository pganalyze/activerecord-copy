# activerecord-copy [ ![](https://img.shields.io/gem/v/activerecord-copy.svg)](https://rubygems.org/gems/activerecord-copy) [ ![](https://img.shields.io/gem/dt/activerecord-copy.svg)](https://rubygems.org/gems/activerecord-copy)

Library to assist using binary COPY into PostgreSQL with activerecord.

Binary copy functionality is based on [pg_data_encoder](https://github.com/pbrumm/pg_data_encoder),
but modified to support additional types, and to prefer column type specifications
over inferred data types.

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-copy'

## Usage

```ruby
class MyModel < ApplicationRecord
  include ActiveRecordCopy
end

MyModel.copy_from_client do

end
```    

## Authors

* [Lukas Fittl](https://github.com/lfittl)

Credits to [Pete Brumm](https://github.com/pbrumm) who wrote pg_data_encoder and
which this library repurposes.

## LICENSE

Copyright (c) 2017, Lukas Fittl <lukas@fittl><br>
activerecord-copy is licensed under the MIT license, see LICENSE file for details.

pg_data_encoder is Copyright (c) 2012, Pete Brumm<br>
pg_data_encoder is included under the terms of the MIT license, see LICENSE file for details.
