class AddVotesCountToPolls < ActiveRecord::Migration[5.0]
  def change
    add_column :polls, :votes_count, :integer
  end
end