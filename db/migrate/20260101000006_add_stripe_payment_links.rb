class AddStripePaymentLinks < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :stripe_secret_key, :string

    add_column :invoices, :stripe_payment_link_id, :string
    add_column :invoices, :stripe_payment_link_url, :string
  end
end
