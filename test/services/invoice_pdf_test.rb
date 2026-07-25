require "test_helper"

class InvoicePdfTest < ActiveSupport::TestCase
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
end
