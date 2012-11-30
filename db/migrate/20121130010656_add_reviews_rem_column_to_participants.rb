class AddReviewsRemColumnToParticipants < ActiveRecord::Migration
  def self.up
    add_column :participants, :reviews_rem, :integer
  end

  def self.down
    remove_column :participants, :reviews_rem
  end
end
