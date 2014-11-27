class Community < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_base, use: :history, sequence_separator: "-"
  mount_uploader :image, CommunityImageUploader  
  has_many :stores
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user
  has_many :products
  belongs_to :user
  
  validates :city, presence: true, :uniqueness => {:scope => :state}
  validates :state, presence: true
  validates :country, presence: true
  validates :lat, presence: true
  validates :lng, presence: true
  validates :info_hash, presence: true, uniqueness: true

  before_save :update_state_name

  scope :online, where("products_count > 0")
  scope :offline, where("products_count = 0")
  scope :in_state, ->(state){ where(state: state) }

  def capitalize_city_name
    self.city.try :capitalize!
  end

  def update_state_name
    self.state_name = State::STATES[self.state] || self.state
  end

  def set_info_hash
    self.info_hash = [self.city, self.state, self.country].reject(&:blank?).map {|x| x.downcase}.join().md5_hash
  end
  before_validation :geocode
  before_validation :capitalize_city_name
  before_validation :set_info_hash
  after_validation do
    if self.errors[:lat].present? or self.errors[:lng].present?
      self.errors[:city].push "Can't generate latitude and longitude"
    end
  end
  default_scope order("city asc")

  searchable auto_index: true do
    integer :id
    string :city
    string :state
    string :country
    time :created_at
    time :updated_at
    # latlon :coordinates do
    #   Sunspot::Util::Coordinates.new(self.lat, self.lng)
    # end
  end

  class << self
    def uniq_states
      Community.unscoped.select("DISTINCT(state), state_name")
    end
    def find_or_create(options = {})
      community = Community.where(city: options[:city], state: options[:state]).first
      return community if community.present?

      return Community.create!(options)
    end

    def search(options = {})
      options.reverse_merge!(page: 1, per_page: 20, precision: 5)
      location = options[:location]
      lat = options[:lat]
      lng = options[:lng]

      query = Sunspot.search(Community) do
        # if options[:keywords]
        #   keywords options[:keywords]
        # end

        if location.present?# && options[:lat].blank? || options[:lng].blank?
          res = Geocoder.coordinates(location)
          if res.present?
            lat = res.first
            lng = res.last
          end 
        end

        # if lat.present? && lng.present?
        #   with(:coordinates).near(lat, lng, precision: options[:precision])
        # end

        paginate page: options[:page], per_page: options[:per_page]
        order_by_geodist(:coordinates, lat, lng) unless lat.blank? || lng.blank?
      end
      # puts "query: #{query.inspect}"
      query
    end

  end

  def to_label
    "#{self.city}, #{self.state}"
  end

  def slug_base
    [(self.to_label || '').gsub(/[^\w\s]/, '')].compact.join(' ')
  end

  def claim(user)
    Postman.notify_of_community_claim(self, user).deliver
  end

  def geocode
    res = Geocoder.coordinates([self.city, self.state, self.country].compact.join(','))
    if res.present?
      self.lat = res.first
      self.lng = res.last
    # else
      # self.errors.add(:city, "Unknown city")
    end
  rescue
    puts "error geocoding community"
  end

  def self.online_offline_in_state(state)
    online = in_state(state).online.select("id, city, state, state_name, slug, products_count")
    offline = in_state(state).offline.select("id, city, state, state_name, slug, products_count")
    return online, offline
  end
end



# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#




# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#

# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#



# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#




# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#





# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#




# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#  description    :text
#  state_name     :string(255)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#  description    :text
#  state_name     :string(255)
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#  description    :text
#


# == Schema Information
#
# Table name: communities
#
#  id             :integer         not null, primary key
#  city           :string(255)     not null
#  state          :string(255)     not null
#  country        :string(255)     default("US"), not null
#  slug           :string(255)     not null
#  info_hash      :string(255)     not null
#  lat            :float           not null
#  lng            :float           not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  follower_count :integer         default(0)
#  stores_count   :integer         default(0)
#  products_count :integer         default(0)
#  description    :text
#  state_name     :string(255)
#  featured       :boolean         default(FALSE)
#  user_id        :integer
#  website        :string(255)
#  phone          :string(255)
#  postal_code    :string(255)
#  image          :string(255)
#

