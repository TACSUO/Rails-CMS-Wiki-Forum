class Wiki < ActiveRecord::Base
  alias_attribute :title, :name
  has_many :wiki_pages
  has_many :wiki_comments
  has_many :wiki_tags

  default_scope order('position, name')
  default_scope where(:archived => true)
  
  after_destroy :fix_group_access
  
  def followers
   posts = self.posts_with_followers
   unique_followers = []
   unique_posts = []
   posts.each do |comment|
    unless unique_posts.find{|c| c.user_id == comment.user_id}
      unique_posts << comment
      unique_followers << comment.user
    end
  end

   return unique_followers
  end
    
  def archive
    self.archived = true
    self.save
  end
  
  private
  def fix_group_access
    UserGroup.all_fix_wiki_access
  end
end

# == Schema Information
#
# Table name: wikis
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  archived     :tinyint    not null, 0
#

