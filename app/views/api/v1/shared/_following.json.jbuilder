if current_user
  json.is_following current_user.followings.where(followable_id: followable.id, followable_type: followable.class).exists?
else
  json.is_following false
end