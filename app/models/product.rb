class Product < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  mount_uploader :image, ProductImageUploader

  acts_as_taggable
  acts_as_rateable
  # Usage
  # @product.tag_list = "awesome, slick, hefty" 
  # @product.tag_list <-- ["awesome", "slick", "hefty"]
  # @product.tags <-- act_as_taggable object
  # @product.tag_counts
  # Product.tag_counts <-- tags for that model

  belongs_to :community, counter_cache: :products_count
  belongs_to :store, counter_cache: :products_count
  belongs_to :user, counter_cache: :products_count
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :list_items, dependent: :destroy    
  has_one :category
  has_many :offers
  
  validates :price, numericality: {greater_than_or_equal_to: 0.0, allow_nil: true}
  validates :user, presence: true

  attr_accessor :like, :store_name # used for the API
  attr_protected :state

  default_scope  where(state: "active")
  scope :previous_latest, lambda{|product| where("store_id = ? and created_at < ?", product.store_id, product.created_at).order("created_at desc").limit(1)}
  scope :previous_last, lambda{|product| where("store_id = ?", product.store_id).order("created_at desc").limit(1)}

  scope :next_latest, lambda{|product| where("store_id = ? and created_at > ?", product.store_id, product.created_at).order("created_at asc").limit(1)}
  scope :next_first, lambda{|product| where("store_id = ?", product.store_id).order("created_at asc").limit(1)}

  scope :active, where(state: "active")
  scope :hidden, where(state: "hidden")
  scope :popular, order("like_count desc")
  scope :featured, where(featured: true)
  scope :in_community, lambda {|community| where("store_id in (?)", community.stores.map(&:id))}
  #scope :price_range, lambda{|price|
  #  where("price = ?", price) if price && price != 0
  #}
  scope :latest, order("created_at desc")


  before_save :check_featured
  before_save :set_community

  after_save :reset_counters
  

  PRICE_RANGES = {
    25 => "$0 - $25",
    50 => "$25 - $50",
    100 => "$50 - $100",
    200 => "$100 - $200",
    500 => "$200 - $500",
    1000 => "$500 - $1000",
    10000 => "$1000 and up"
  }

  searchable auto_index: true do
    string :class_name do
       self.class.name
    end
    integer :id
    text :name, boost: 30
    text :description, boost: 10
    integer :like_count
    double :price
    time :created_at
    time :updated_at
    integer :community_id
    string :product_state do
      self.state
    end
    text :city, :as => :city_text_exact do
      if self.store.present?
        self.store.city
      end
    end
    text :state, :as => :state_text_exact do
      if self.store.present?
        self.store.state
      end
    end
    integer :category_id
    text :tag_list, boost: 20
    boolean :featured
    text :store_name do
      if self.store.present?
        self.store.name
      end
    end
    text :store_description do
      if self.store.present?
        self.store.description
      end
    end
    text :category_name do
      if self.category.present?
        self.category
      end
    end
    latlon(:coordinates) do
      if self.store.present?
        Sunspot::Util::Coordinates.new(self.store.lat, self.store.lng) 
      end
    end
    text :owner_name do
      if self.user.present?
        self.user.name
      end
    end
  end

  def lat
    self.try(:store).try(:lat)
  end

  def lng
    self.try(:store).try(:lng)
  end

  class << self

    def search(options = {})
      options.reverse_merge!(page: 1, per_page: 20, precision: 3)
      location = options[:location]
      lat = options[:lat]
      lng = options[:lng]

      query = Sunspot.search(Product) do
        if options[:keywords]
          fulltext options[:keywords] do
            fields(:name, :store_name, :category_name, :description, :store_description)
          end
        end
        if location.present?
          res = Geocoder.coordinates(location)
          if res.present?
            lat = res.first
            lng = res.last
          end 
        end
        if !(options.has_key?(:paginate) && options[:paginate] == false)
          paginate page: options[:page], per_page: options[:per_page]
        end
        with :community_id, options[:community_id] if options[:community_id]
        with :category_id, options[:category] if options[:category]
        with :price, options[:price_range] if options[:price_range].try("!=", 0)
        without(:product_state, "hidden")
        with(:featured, true) if options[:featured]
        fulltext "\"#{options[:city]}\"", {:fields => :city} if options[:city]
        fulltext options[:state], {:fields => :state} if options[:state]
         
        if options[:random]
          order_by(:random) 
        elsif options[:popular] 
          order_by(:like_count, :desc)
        else
          order_by(:created_at, :desc)
        end

        unless lat.blank? || lng.blank? 
          if options[:latest] || options[:popular] || options[:random] || options[:radius]
            #just flter without ordering by location to prevent conflict with other ordering
            with(:coordinates).in_radius(lat, lng, (options[:radius]|| 100000), :bbox => true)
          else
            order_by_geodist(:coordinates, lat, lng)
          end
        end
      end
      query
    end

    def price_range(price)
      if price == "any"
        self.where("price is not null")
      else
        price = price.to_i
        return scoped if price.zero?
        self.where(price: price)
      end
    end
  end

    def check_reindex
      if Product.search(:per_page => 200).hits.count < 200
        Product.reindex
      end
    end

  def reset_counters
    Store.reset_counters(self.store_id, :products) if self.store.present?
    User.reset_counters(self.user_id, :products) if self.user_id.present?
  end
  
  def check_featured
    if self.store && self.owner == self.store.owner && self.store.featured 
      self.featured = true      
    end
    if self.store && self.owner != self.store.owner && self.store.featured 
      self.state = :hidden
    end
      # self.save    
  end

  def image_url size=nil
    return self.image.url(size) if size 
    self.image.url
  end
  
  def image_from_base64 encoded_img, filename
    io = FilelessIO.new(Base64.decode64(encoded_img))
    io.original_filename = filename
     
    self.image = io
  end
  
  def owner
    self.user
  end

  def to_jq_upload
    {
      "name" => name,
      "price" => price,
      "image_url" => image.url(:original)      
    }
  end

  def category
    return nil unless read_attribute(:category_id)
    Category.find_by_id(read_attribute(:category_id)).try(:name)    
  end
  
  def category= name
    self.category_id = Category.find_by_name(name).try(:id)
  end
  
  def store_name= name    
    product_store = Store.find_by_name(name)  
    self.store = product_store if product_store
  end

  def store_name    
    self.store.try(:name)
  end

  def set_community
    if !self.store.blank? && self.store_id_changed?
      self.community = self.store.community      
    end
  end

  def set_city_state
    self.store_city = self.store.city
    self.store_state = self.store.state
  end

end

# == Schema Information
#
# Table name: products
#
#  id           :integer         not null, primary key
#  store_id     :integer
#  user_id      :integer
#  image        :string(255)
#  name         :string(255)
#  description  :text
#  price        :decimal(7, 2)
#  state        :string(255)     default("active"), not null
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  like_count   :integer         default(0)
#  featured     :boolean         default(FALSE)
#  category_id  :integer
#  community_id :integer
#

# == Schema Information
#
# Table name: products
#
#  id           :integer         not null, primary key
#  store_id     :integer
#  user_id      :integer
#  image        :string(255)
#  name         :string(255)
#  description  :text
#  price        :decimal(7, 2)
#  state        :string(255)     default("active"), not null
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  like_count   :integer         default(0)
#  featured     :boolean         default(FALSE)
#  category_id  :integer
#  community_id :integer
#  store_state  :string(255)     default("")
#  store_city   :string(255)     default("")
#

