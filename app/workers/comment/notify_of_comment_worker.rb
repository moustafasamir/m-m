class Comment::NotifyOfCommentWorker < DJ::Worker

  def perform
    comment = Comment.find(self.id)
    Comment.transaction do
      user_ids = comment.commentable.comments.map(&:user_id)
      user_ids << comment.commentable.likes.map(&:user_id)
      owner_id = comment.commentable.user_id
      user_ids << owner_id
      user_ids.flatten!
      user_ids.uniq!
      # puts "user_ids: #{user_ids.inspect}"
      # don't send the email to the person who commented:
      user_ids = user_ids.reject {|x| x == comment.user_id}
      # puts "user_ids: #{user_ids.inspect}"
      user_ids.each do |user_id|
        if comment.user_id == owner_id
          Postman.notify_of_new_comment_by_owner(comment, User.find(user_id)).deliver
        else
          Postman.notify_of_new_comment(comment, User.find(user_id)).deliver
        end
      end
    end
  end

  
end