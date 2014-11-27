json.(@products) do |json, product|
  json.partial! product
end