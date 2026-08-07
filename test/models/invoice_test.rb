require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  test "assigns an invoice number automatically on create" do
    invoice = Invoice.new(contact: contacts(:jane), status: "draft",
                           issue_date: Date.current, due_date: Date.current + 7)
    assert invoice.save
    assert_match(/\AINV-\d{4}\z/, invoice.invoice_number)
  end

  test "does not overwrite an explicitly set invoice number" do
    invoice = Invoice.new(contact: contacts(:jane), status: "draft", invoice_number: "INV-9999",
                           issue_date: Date.current, due_date: Date.current + 7)
    assert invoice.save
    assert_equal "INV-9999", invoice.invoice_number
  end

  test "requires a valid status" do
    invoice = invoices(:draft_invoice)
    invoice.status = "not-a-real-status"
    assert_not invoice.valid?
  end

  test "subtotal sums line items" do
    invoice = invoices(:draft_invoice)
    expected = invoice.invoice_items.sum { |item| item.quantity * item.unit_price }
    assert_equal expected, invoice.subtotal
  end

  test "gst_amount is 10% of the subtotal when gst is applicable" do
    invoice = invoices(:draft_invoice)
    invoice.update!(gst_applicable: true)
    assert_equal (invoice.subtotal * BigDecimal("0.10")).round(2), invoice.gst_amount
  end

  test "gst_amount is zero when gst is not applicable" do
    invoice = invoices(:draft_invoice)
    invoice.update!(gst_applicable: false)
    assert_equal BigDecimal("0"), invoice.gst_amount
  end

  test "total adds gst_amount to subtotal" do
    invoice = invoices(:draft_invoice)
    invoice.update!(gst_applicable: true)
    assert_equal invoice.subtotal + invoice.gst_amount, invoice.total

    invoice.update!(gst_applicable: false)
    assert_equal invoice.subtotal, invoice.total
  end

  test "clears a cached Stripe payment link when gst_applicable changes" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_123", stripe_payment_link_url: "https://buy.stripe.com/test_abc")

    invoice.update!(gst_applicable: !invoice.gst_applicable)

    assert_nil invoice.stripe_payment_link_id
    assert_nil invoice.stripe_payment_link_url
  end

  test "overdue? is true only for sent invoices past their due date" do
    assert invoices(:overdue_invoice).overdue?
    assert_not invoices(:draft_invoice).overdue?
  end

  test "mark_paid! sets status and paid_at" do
    invoice = invoices(:draft_invoice)
    invoice.mark_paid!
    assert_equal "paid", invoice.status
    assert_not_nil invoice.paid_at
  end
end
