class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable, :confirmable,
         :recoverable, :rememberable, :jwt_authenticatable, jwt_revocation_strategy: self

  # Include default devise modules. Others available are:
  #  :lockable, :timeoutable, :trackable and :omniauthable
  # has_secure_password

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :password, presence: true, confirmation: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :password_confirmation, presence: true, if: -> { (new_record? || !password.nil?) && provider != "google" }
  validates :name, length: { maximum: 50 }, format: { without: /[<>:;?]/ }, allow_blank: true
  validate :photo_must_be_a_valid_url, if: -> { photo.present? }

  private

  def photo_must_be_a_valid_url
    uri = URI.parse(photo)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:photo, "must be a valid URL")
    end
  rescue URI::InvalidURIError
    errors.add(:photo, "must be a valid URL")
  end
end
