class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def line_total
    quantity.to_d * unit_price.to_d
  end
end
