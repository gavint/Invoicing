class Setting < ApplicationRecord
  # Singleton-style settings record. Always use Setting.instance to fetch it.
  def self.instance
    first_or_create!(company_name: "My Company", company_email: "you@example.com")
  end

  def stripe_configured?
    stripe_secret_key.present?
  end
end
