class ConvertAgeToDob < ActiveRecord::Migration
  def change
    add_column :users, :dob, :datetime
    remove_column :users, :age, :integer
  end
end
