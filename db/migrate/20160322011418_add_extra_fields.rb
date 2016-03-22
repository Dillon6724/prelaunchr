class AddExtraFields < ActiveRecord::Migration
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :street_address, :string
    add_column :users, :city, :string
    add_column :users, :state, :string
    add_column :users, :zip, :string
    add_column :users, :occupation, :string
    add_column :users, :how_long, :string
    add_column :users, :how_heard, :string
  end
  def down
    remove_column :users, :first_name, :string
    remove_column :users, :last_name, :string
    remove_column :users, :street_address, :string
    remove_column :users, :city, :string
    remove_column :users, :state, :string
    remove_column :users, :zip, :string
    remove_column :users, :occupation, :string
    remove_column :users, :how_long, :string
    remove_column :users, :how_heard, :string
  end
end
