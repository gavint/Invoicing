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

  test "total sums line items" do
    invoice = invoices(:draft_invoice)
    expected = invoice.invoice_items.sum { |item| item.quantity * item.unit_price }
    assert_equal expected, invoice.total
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
