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

  test "saving an item clears the invoice's cached Stripe payment link" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    invoice_items(:item_one).update!(unit_price: 999)

    assert_nil invoice.reload.stripe_payment_link_id
    assert_nil invoice.stripe_payment_link_url
  end

  test "destroying an item clears the invoice's cached Stripe payment link" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    invoice_items(:item_one).destroy

    assert_nil invoice.reload.stripe_payment_link_id
    assert_nil invoice.stripe_payment_link_url
  end
end
