class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :async

  validate :email_is_unique, on: :create
  after_create :create_account

  private
    # Email should be unique in Account Model
    def email_is_unique
      # Do not validate email if errors are already present
      unless self.errors[:email].empty?
        return false
      end

      unless Account.find_by_email(email).nil?
        errors.add(:email, "is already being used")
      end
    end

    def create_account
      account = Account.new(:email => email)
      account.save!
    end

end
