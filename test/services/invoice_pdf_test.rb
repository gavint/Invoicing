require "test_helper"
require "minitest/mock"

class InvoicePdfTest < ActiveSupport::TestCase
  include ActionView::Helpers::NumberHelper

  test "renders PDF bytes for an invoice" do
    pdf = InvoicePdf.new(invoices(:draft_invoice)).render
    assert_kind_of String, pdf
    assert pdf.start_with?("%PDF")
  end

  test "includes a payment details section when settings has bank info" do
    html = InvoicePdf.new(invoices(:draft_invoice)).to_html

    assert_includes html, "Payment Details"
    assert_includes html, settings(:default).bank_account_name
    assert_includes html, settings(:default).bank_bsb
    assert_includes html, settings(:default).bank_account_number
    assert_includes html, settings(:default).pay_id
  end

  test "omits the payment details section when settings has no bank info" do
    settings(:default).update!(bank_account_name: nil, bank_bsb: nil, bank_account_number: nil, pay_id: nil)

    html = InvoicePdf.new(invoices(:draft_invoice)).to_html

    assert_not_includes html, "Payment Details"
  end

  test "omits blank payment fields but keeps the ones that are filled in" do
    settings(:default).update!(bank_account_name: nil, bank_bsb: nil, bank_account_number: nil, pay_id: "pay@example.test")

    html = InvoicePdf.new(invoices(:draft_invoice)).to_html

    assert_includes html, "Payment Details"
    assert_includes html, "pay@example.test"
    assert_not_includes html, "Account name"
    assert_not_includes html, "BSB"
  end

  test "shows the status for a draft invoice" do
    html = InvoicePdf.new(invoices(:draft_invoice)).to_html

    assert_includes html, %(class="status status-draft">DRAFT)
  end

  test "shows the status for a paid invoice" do
    html = InvoicePdf.new(invoices(:paid_invoice)).to_html

    assert_includes html, %(class="status status-paid">PAID)
  end

  test "hides the status for a sent invoice that isn't overdue" do
    html = InvoicePdf.new(invoices(:sent_invoice)).to_html

    assert_not_includes html, "<th>Status</th>"
  end

  test "shows OVERDUE instead of SENT for a sent invoice past its due date" do
    html = InvoicePdf.new(invoices(:overdue_invoice)).to_html

    assert_includes html, %(class="status status-overdue">OVERDUE)
    assert_not_includes html, "SENT"
  end

  test "omits the pay-online link when Stripe isn't configured" do
    html = InvoicePdf.new(invoices(:draft_invoice)).to_html

    assert_not_includes html, "Pay this invoice online"
  end

  test "includes a pay-online link when Stripe is configured" do
    settings(:default).update!(stripe_secret_key: "sk_test_123")
    fake_link = Struct.new(:id, :url).new("plink_123", "https://buy.stripe.com/test_abc")

    html = Stripe::PaymentLink.stub :create, fake_link do
      InvoicePdf.new(invoices(:draft_invoice)).to_html
    end

    assert_includes html, "Pay this invoice online"
    assert_includes html, "https://buy.stripe.com/test_abc"
  end

  test "omits the pay-online link for a paid invoice even if Stripe is configured" do
    settings(:default).update!(stripe_secret_key: "sk_test_123")

    html = InvoicePdf.new(invoices(:paid_invoice)).to_html

    assert_not_includes html, "Pay this invoice online"
  end

  test "labels the document a tax invoice and breaks out GST when gst is applicable" do
    invoice = invoices(:draft_invoice)
    invoice.update!(gst_applicable: true)

    html = InvoicePdf.new(invoice).to_html

    assert_includes html, "TAX INVOICE"
    assert_includes html, "GST (10%)"
    assert_includes html, number_to_currency(invoice.gst_amount)
    assert_includes html, number_to_currency(invoice.total)
  end

  test "labels the document a plain invoice and omits GST when gst is not applicable" do
    invoice = invoices(:draft_invoice)
    invoice.update!(gst_applicable: false)

    html = InvoicePdf.new(invoice).to_html

    assert_includes html, ">INVOICE<"
    assert_not_includes html, "TAX INVOICE"
    assert_not_includes html, "GST (10%)"
    assert_includes html, number_to_currency(invoice.total)
  end
end
