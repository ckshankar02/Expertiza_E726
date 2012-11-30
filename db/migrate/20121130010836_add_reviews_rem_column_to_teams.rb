class AddReviewsRemColumnToTeams < ActiveRecord::Migration
  def self.up
    add_column :teams, :reviews_rem, :integer
  end

  def self.down
    remove_column :teams, :reviews_rem
  end
end
