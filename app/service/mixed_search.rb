class MixedSearch
  def initialize(options={})
    @options = options
  end

  def search
    prepare_options
    geo_parse
    options = @options
    query = Sunspot.search(Store, Product) do
      if options[:keywords]
        fulltext options[:keywords] do
          fields(:name, :store_name, :category_name, :description, :store_description)
        end
      end
      fulltext "\"#{options[:city]}\"", {:fields => :city} if options[:city]
      fulltext options[:state], {:fields => :state} if options[:state]
      with :community_id, options[:community_id] if options[:community_id]
      paginate(page: options[:page], per_page: options[:per_page]) unless options.has_key?(:paginate) && options[:paginate]==false
      order_by(:class_name, :desc)
      order_by(:created_at, :desc) if options[:latest]

      unless @lat.blank? || @lng.blank?
        if options[:latest] || options[:popular] || options[:random] || options[:radius]
          with(:coordinates).in_radius(lat, lng, (options[:radius]|| 1000), :bbox => true)
        else
          order_by_geodist(:coordinates, lat, lng)
        end
      end
    end
    query.results
  end

  def prepare_options
    @options.reverse_merge!(page: 1, per_page: 20, precision: 4)
  end

  def geo_parse
    location = @options[:location]
    @lat = @options[:lat]
    @lng = @options[:lng]

    if location.present?
      res = Geocoder.coordinates(location)
      @lat, @lng = res.first, res.last if res.present?
    end
  end
end