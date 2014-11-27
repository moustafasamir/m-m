json.extract! product, :id, :name, :description, :price, :state, :like_count, :tag_list, :user_id, :store_id, :created_at, :updated_at, :lat,:lng
json.model_name product.class.name
json.rate product.average_rating

images = {full: product.image_url}
product.image.versions.each do |key, value|
  images[key.to_s] = value.to_s
end

json.image images

json.permissions permissions(product)

json.category product.category

if product.category
  json.category_url CGI.escape(product.category) 
end

if current_user
  json.like product.likes.where(user_id: current_user.id).first
end

json.comments_size product.comments.count

if product.store_id
  json.store_name product.store.try(:name)
end
