class Guest < ActiveRecord::Base
  mount_uploader :image, PictureUploader

  has_many :providers
  has_many :shopquik_todo_lists, class_name: 'Shopquik::TodoList', foreign_key: 'guest_id'
  has_many :budgets_monthly_earnings, class_name: 'Budgets::MonthlyEarning', foreign_key: 'guest_id'

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2, :facebook],
         :authentication_keys => [:login]

  def login=(login)
    @login = login
  end

  def login
    @login || self.username || self.email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_hash).first
    end
  end

  def self.fetch_or_store_oauth(auth, signed_in_resource=nil)
    data = auth.info
    data_extra = auth.extra.raw_info

    # get the provider from Provider model
    provider = Provider.get_provider(auth)
    guest = provider.guest

    # if guest is nil, find a user with same email or create if not found.
    if guest.nil?
      guest = Guest.where(email: data.email).first_or_create do |g|
        g.email = data.email
        g.password = 'password'
        g.first_name = data.first_name
        g.last_name = data.last_name
        g.image = data.image
        g.sex = data_extra.gender
        g.birthday = data_extra.birthday
      end
    end

    # Associate this user with a provider if no association exist
    if provider.guest != guest
      provider.guest = guest
      provider.save
    end

    guest
  end
end
