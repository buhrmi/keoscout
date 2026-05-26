class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.string :provider
      t.string :provider_id
      t.json :info
      t.integer :user_id

      t.timestamps

      t.index [ :provider, :provider_id ], unique: true
    end
  end
end
