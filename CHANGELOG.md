# Changelog

## Latest 2022-03-16

* Big refactoring including:
  * Support for mac address
  * Fix issue with `time` type
  * Fix issue with negative numerics
  * Remove support for `send_at_once`, it is now synchronous by default
  * Use `copy_data` block from pg
  * Use `sync_put_copy_data` from pg and flush at the end
  * Add support for `geometry` and `geogrphy`
  * Add integrations tests using a Dummy rails App (See [spec/dummy](spec/dummy))
  * Remove the unused `use_tempfile` options from `EncodeForCopy`
  * Add explicit dependency to the [pg](https://rubygems.org/gems/pg/versions/1.3.4) gem, with a version minimum to 1.3.0 as we are using the `sync_put_copy_data` method
  
## 1.1.0       2018-05-24

* Add support for range data types
* Fix bugs in NUMERIC data type encoding


## 1.0.1       2017-07-22

* Explicitly include ActiveRecord to ensure copy_from_client gets defined


## 1.0.0       2017-07-22

* Initial release after fork from pg_data_encoder
