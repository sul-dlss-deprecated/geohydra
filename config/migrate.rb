require 'rails'
class CreateRegisteredLayer < ActiveRecord::Migration
  def change
    create_table :registered_layers do |t|
      t.string :druid
      t.string :layer
      t.string :title
      add_index :druid
    end
  end
end