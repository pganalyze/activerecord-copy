class CreateMyModels < ActiveRecord::Migration[6.1]
  def change
    create_table :my_models do |t|
      t.binary :binary
      t.boolean :boolean
      t.date :date
      t.datetime :datetime
      t.decimal :decimal
      t.float :float
      t.integer :integer
      t.bigint :bigint
      t.string :string
      t.text :text
      t.time :time
      t.timestamp :timestamp
      t.geometry :geometry

      t.json :json
      t.jsonb :jsonb

      t.inet :inet
      t.cidr :cidr
      t.macaddr :macaddr

      t.int4range :int4range
      t.numrange :numrange
      t.tstzrange :tstzrange
      t.daterange :daterange
    end
  end

end
