class Invoice < ApplicationRecord
  STATUSES = %w[draft sent paid void].freeze
  GST_RATE = BigDecimal("0.10")

  belongs_to :contact
  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items, reject_if: :all_blank, allow_destroy: true

  validates :status, inclusion: { in: STATUSES }
  validates :invoice_number, presence: true, uniqueness: true

  before_validation :assign_invoice_number, on: :create
  after_update :clear_stale_payment_link, if: :saved_change_to_gst_applicable?

  def subtotal
    invoice_items.sum(&:line_total)
  end

  def gst_amount
    return BigDecimal("0") unless gst_applicable?

    (subtotal * GST_RATE).round(2)
  end

  def total
    subtotal + gst_amount
  end

  def overdue?
    status == "sent" && due_date.present? && due_date < Date.current
  end

  def mark_paid!
    update!(status: "paid", paid_at: Time.current)
  end

  private

  def assign_invoice_number
    return if invoice_number.present?

    last_id = Invoice.maximum(:id) || 0
    self.invoice_number = format("INV-%04d", last_id + 1)
  end

  # Mirrors InvoiceItem#clear_stale_payment_link: toggling gst_applicable
  # changes #total without touching any invoice_items, so it needs its own
  # trigger to invalidate a cached Stripe payment link.
  def clear_stale_payment_link
    update_columns(stripe_payment_link_id: nil, stripe_payment_link_url: nil) if stripe_payment_link_url.present?
  end
end
