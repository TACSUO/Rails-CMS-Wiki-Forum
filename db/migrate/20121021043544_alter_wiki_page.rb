class AlterWikiPage < ActiveRecord::Migration
  def self.up
		add_column :users, :following_wiki_ids, :text
  end

  def self.down
		remove_column :users, :following_wiki_ids
  end
end
