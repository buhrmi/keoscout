class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :locale, default: "en"

      t.integer :earnings, default: 0
      t.integer :talents_count, default: 0
      t.integer :scout_id
      t.timestamps
    end
  end
end
