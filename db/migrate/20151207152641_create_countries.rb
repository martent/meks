class CreateCountries < ActiveRecord::Migration[4.2]
  def change
    create_table :countries do |t|
      t.string :name

      t.timestamps null: false
    end
    add_index :countries, :name, unique: true
  end
end
