class Follow < ActiveRecord::Base
  belongs_to :user, counter_cache: :following_count
  # belongs_to :user , :inverse_of => :user_followings , :counter_cache => :user_following_count
  belongs_to :followable, polymorphic: true, counter_cache: :follower_count

  validates :followable, presence: true
  # validates_uniqueness_of :user_id, :scope => [:followable_type, :followable_id], :message => "You are already following this Object"
  validate :unique_to_user
  validate :not_follow_self

  # after_save :reset_follower_counts
  after_create :add_follow_to_feeds
  after_destroy :remove_notifications

  def remove_notifications
    notifications = Notification.where(:notifiable_id => self.id).where(:notifiable_type => :Follow)
    notifications.each{|n|
      n.destroy
    }
    return true
  end  

  def unique_to_user
    if Follow.where(user_id: self.user_id, followable_id: self.followable_id, followable_type: self.followable_type).exists?
      self.errors[:base] = "You are already following this #{self.followable_type}"
    end
  end

  def not_follow_self
    if self.followable == self.user
      errors.add(:user, "Can't follow yourself")
    end
  end
  # def reset_follower_counts
  #   count = Follow.where(followable_type: self.followable_type, followable_id: self.followable_id).count
  #   self.followable.update_attribute(:follower_count, count)
  # end
  
  #Track this activity 
  def add_follow_to_feeds    
    if self.followable.is_a?(Store)       
      Notification.notify_by_follow(self.followable.user, self)
    elsif self.followable.is_a?(User)       
      Notification.notify_by_follow(self.followable, self)
    end     
  end

end

# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#



# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#


# == Schema Information
#
# Table name: follows
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  followable_id   :integer
#  followable_type :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

