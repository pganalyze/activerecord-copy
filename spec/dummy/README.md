# Dummy Rails App

Dummy rails app use for the integration tests.
It requires postgres to be running (see [start-local.sh](../../start-local-db.sh))

Set up the DB:
```
bundle install
DATABASE_URL='postgis://postgres:postgres@localhost:5577' rake db:create db:migrate db:test:prepare
```
