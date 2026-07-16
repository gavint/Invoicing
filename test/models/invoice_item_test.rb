require "test_helper"

class InvoiceItemTest < ActiveSupport::TestCase
  test "line_total multiplies quantity and unit price" do
    item = invoice_items(:item_one)
    assert_equal item.quantity * item.unit_price, item.line_total
  end

  test "invalid with zero quantity" do
    item = InvoiceItem.new(invoice: invoices(:draft_invoice), description: "Thing", quantity: 0, unit_price: 10)
    assert_not item.valid?
  end

  test "invalid with a negative unit price" do
    item = InvoiceItem.new(invoice: invoices(:draft_invoice), description: "Thing", quantity: 1, unit_price: -5)
    assert_not item.valid?
  end

  test "invalid without a description" do
    item = InvoiceItem.new(invoice: invoices(:draft_invoice), quantity: 1, unit_price: 10)
    assert_not item.valid?
  end
end
