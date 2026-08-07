class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  after_save :clear_stale_payment_link
  after_destroy :clear_stale_payment_link

  def line_total
    quantity.to_d * unit_price.to_d
  end

  private

  # A cached Stripe payment link is only valid for the total it was created
  # for, so any change to the items behind that total invalidates it - the
  # next request for a link (see StripePaymentLink#url) will regenerate one
  # for the current total. See Invoice#clear_stale_payment_link for the
  # equivalent trigger when gst_applicable changes instead of the items.
  def clear_stale_payment_link
    invoice.update_columns(stripe_payment_link_id: nil, stripe_payment_link_url: nil) if invoice.stripe_payment_link_url.present?
  end
end
