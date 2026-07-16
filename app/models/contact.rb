class Contact < ApplicationRecord
  has_many :invoices, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def display_name
    company_name.presence || name
  end
end
