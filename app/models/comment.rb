class Comment < ActiveRecord::Base
  belongs_to :user

  belongs_to :commentable, polymorphic: true
  validates :commentable, presence: true

  validates :body, presence: true

  before_save :clean_body
  before_save :moderate_reviews
  after_create :notify_of_comment#, :if => :active
  # default_scope  where(active: true)
  default_scope  order("created_at desc")

  scope :active, where(active: true)
  scope :hidden, where(active: false)

  after_destroy :remove_notifications

  def remove_notifications
    notifications = Notification.where(:notifiable_id => self.id).where(:notifiable_type => :Comment)
    notifications.each{|n|
      n.destroy
    }
    return true
  end  





  def clean_body
    self.body.strip! unless self.body.blank?
  end

  def notify_of_comment
    user_ids = self.commentable.comments.map(&:user_id)
    user_ids << self.commentable.likes.map(&:user_id)
    owner_id = self.commentable.user_id
    user_ids << owner_id
    user_ids.flatten!
    user_ids.uniq!
    user_ids = user_ids.reject {|x| x == self.user_id}
    #Add notification
    user_ids.each do |notifier|
      Notification.notify_by_comment(notifier, self)
    end
    Comment::NotifyOfCommentWorker.enqueue(id: self.id)
    APN::App.delay.send_notifications
    return true
  end
  
  def moderate_reviews
    if self.commentable.is_a? Product
      if self.commentable.store && self.user != self.commentable.store.owner && self.commentable.store.featured 
          self.active = false
      end
    elsif self.commentable.is_a? Store
      if self.commentable.featured and self.user != self.commentable.user
        self.active = false
      end
    end
    return true
  end

end


# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#



# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#


# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#


# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#





# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean         default(TRUE)
#


# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean         default(TRUE)
#



# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  active     :boolean         default(TRUE)
#












# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#


# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  active     :boolean         default(TRUE)
#


# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  product_id :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  active     :boolean         default(TRUE)
#





# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  body       :text            not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  active     :boolean         default(TRUE)
#  product_id :integer
#


# == Schema Information
#
# Table name: comments
#
#  id               :integer         not null, primary key
#  user_id          :integer         not null
#  body             :text            not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  active           :boolean         default(TRUE)
#  commentable_id   :integer
#  commentable_type :string(255)
#


# == Schema Information
#
# Table name: comments
#
#  id               :integer         not null, primary key
#  user_id          :integer         not null
#  body             :text            not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  active           :boolean         default(TRUE)
#  commentable_id   :integer
#  commentable_type :string(255)
#


# == Schema Information
#
# Table name: comments
#
#  id               :integer         not null, primary key
#  user_id          :integer         not null
#  body             :text            not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  active           :boolean         default(TRUE)
#  commentable_id   :integer
#  commentable_type :string(255)
#




# == Schema Information
#
# Table name: comments
#
#  id               :integer         not null, primary key
#  user_id          :integer         not null
#  body             :text            not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  active           :boolean         default(TRUE)
#  commentable_id   :integer
#  commentable_type :string(255)
#




# == Schema Information
#
# Table name: comments
#
#  id               :integer         not null, primary key
#  user_id          :integer         not null
#  body             :text            not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  active           :boolean         default(TRUE)
#  commentable_id   :integer
#  commentable_type :string(255)
#

