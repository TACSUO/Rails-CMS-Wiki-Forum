# User Group
#
#
#
class UserGroup < ActiveRecord::Base
  SPECIAL_ACCESS = ['Wiki Reader', 'Wiki Editor', 'Forum Poster', 'Forum Moderator']

  # stored as an Array - list of indexes of SPECIAL_ACCESS
  serialize :special, Hash

  has_and_belongs_to_many :users

  before_save :strip_none_from_special

  class << self
    def find_by_name(name)
      @groups ||= {}
      @groups[name] ||= find( :first, :conditions => { :name => name })
    end

    def find_or_create_by_name(name)
      find_by_name(name) || create(:name => name)
    end

    def find_all_with_access_to(wiki_or_forum)
      if wiki_or_forum.is_a?(Wiki)
        find(:all).select { |ug| ug.wikis.keys.include?(wiki_or_forum.id.to_s) }
      else
        find(:all).select { |ug| ug.forums.keys.include?(wiki_or_forum.id.to_s) }
      end
    end
  
    def find_all_with_access_to_writable_wiki_or_forum
      user_groups = find :all, :order => 'name'
      writable_groups = user_groups
      user_groups.each do |user_group|
        writable_groups.delete(user_group) unless user_group.hasWritables
      end
      
    end
    
    def all_fix_wiki_access
      user_groups = find :all
      user_groups.each do |user_group|
        user_group.fix_wiki_access
        user_group.save
      end
    end

    def all_fix_forum_access
      user_groups = find :all
      user_groups.each do |user_group|
        user_group.fix_forum_access
        user_group.save
      end
    end
    
    def set_wiki_access_readonly(wiki)
      user_groups = find_all_with_access_to wiki
      user_groups.each do |user_group|
        user_group.set_wiki_readonly wiki.id.to_s
        user_group.save
      end
    end

  end

  # not actually forums, but a hash of forum ids and access
  def forums
    self.special ||= {}
    self.special[:forums] ||= {}
    special[:forums]
  end

  def add_forum(forum, access)
    if forum.new_record?
      raise "no forum ID found!"
    end
    self.special ||= {}
    self.special[:forums] ||= {}
    self.special[:forums][forum.id.to_s] = access
  end

  # not actually wikis, but a hash of wiki ids and access
  def wikis
    self.special ||= {}
    self.special[:wikis] ||= {}
    special[:wikis]
  end

  def forum_access=(access_hash)
    self.special ||= {}
    self.special[:forums] = access_hash
  end

  def wiki_access=(access_hash)
    self.special ||= {}
    self.special[:wikis] = access_hash
  end
  
  def hasWritables
    w_ids = special[:wikis].keys
    w_ids.each do |w_id|
      if( self.special[:wikis][w_id] == 'write')
         return true
      end
    end
    
    f_ids = special[:forums].keys
    f_ids.each do |f_id|
      if(self.special[:forums][f_id] == 'write')
        return true
      end
    end
    
    return false
  end
  
  def set_wiki_readonly(id)
    w_ids = special[:wikis].keys
    w_ids.each do |w_id|
      if(id == w_id)
        self.special[:wikis][w_id] = 'read'
      end
    end
  end

  def fix_wiki_access
    w_ids = special[:wikis].keys
    w_ids.each do |w_id|
      w = Wiki.find :first, :conditions => { :id => w_id }
      self.special[:wikis].delete(w_id) if w.nil?
    end
  end
 
  def fix_forum_access
    f_ids = special[:forums].keys
    f_ids.each do |f_id|
      f = Forum.find :first, :conditions => { :id => f_id }
      self.special[:forums].delete(f_id) if f.nil?
    end
  end

  def grants_access_to_forum?(forum_or_forum_id)
    forum_id = forum_or_forum_id.is_a?(Forum) ? forum_or_forum_id.id : forum_or_forum_id
    forums[forum_id.to_s]
  end

  def grants_access_to_wiki?(wiki_or_wiki_id)
    wiki_id = wiki_or_wiki_id.is_a?(Wiki) ? wiki_or_wiki_id.id : wiki_or_wiki_id
    wikis[wiki_id.to_s]
  end
 
  # returns something human readable, like:
  # Forum: Some Forum 1 (Read), Forum: Some Forum 2 (Write), Wiki: Some Wiki 1 (Read), Wiki: Some Wiki 2 (Write)
  def access_string
    forum_strings = forums.map { |f_id, f_access| "Forum: #{Forum.find(f_id).name} (#{f_access.titleize})" }
    wiki_strings = wikis.map { |w_id, w_access| "Wiki: #{Wiki.find(w_id).name} (#{w_access.titleize})" }
    [forum_strings + wiki_strings].join(', ')
  end

  def access_as_html
    forum_strings = forums.map { |f_id, f_access| "<li>Forum: #{Forum.find(f_id).name} <em>(#{f_access.titleize})</em></li>" }
    wiki_strings = wikis.map { |w_id, w_access| "<li>Wiki: #{Wiki.find(w_id).name} <em>(#{w_access.titleize})</em></li>" }
    "<ul>\n" + [forum_strings + wiki_strings].join("\n") + "</ul>\n"
  end
  
  def drop_users(drop_user_ids)
    drop_user_ids = [*drop_user_ids].compact.map(&:to_i)
    self.user_ids = user_ids - drop_user_ids
    self.save
  end

  private
  def strip_none_from_special
    # make sure the hashes are set up so we don't error out
    forums
    wikis

    self.special[:forums].reject! { |f_id, access| access == "none" }
    self.special[:wikis].reject!  { |w_id, access| access == "none" }
  end
end

# == Schema Information
#
# Table name: user_groups
#
#  id      :integer         not null, primary key
#  name    :string(255)
#  special :text(255)
#

