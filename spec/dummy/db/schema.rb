# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_03_16_104731) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "my_models", force: :cascade do |t|
    t.binary "binary"
    t.boolean "boolean"
    t.date "date"
    t.datetime "datetime"
    t.decimal "decimal"
    t.float "float"
    t.integer "integer"
    t.bigint "bigint"
    t.string "string"
    t.text "text"
    t.time "time"
    t.datetime "timestamp"
    t.geometry "geometry", limit: {:srid=>0, :type=>"geometry"}
    t.json "json"
    t.jsonb "jsonb"
    t.inet "inet"
    t.cidr "cidr"
    t.macaddr "macaddr"
    t.int4range "int4range"
    t.numrange "numrange"
    t.tstzrange "tstzrange"
    t.daterange "daterange"
  end

end
