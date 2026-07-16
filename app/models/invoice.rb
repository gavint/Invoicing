class Invoice < ApplicationRecord
  STATUSES = %w[draft sent paid void].freeze

  belongs_to :contact
  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items, reject_if: :all_blank, allow_destroy: true

  validates :status, inclusion: { in: STATUSES }
  validates :invoice_number, presence: true, uniqueness: true

  before_validation :assign_invoice_number, on: :create

  def total
    invoice_items.sum(&:line_total)
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
end
