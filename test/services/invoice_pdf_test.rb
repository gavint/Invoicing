require "test_helper"

class InvoicePdfTest < ActiveSupport::TestCase
  test "renders PDF bytes for an invoice" do
    pdf = InvoicePdf.new(invoices(:draft_invoice)).render
    assert_kind_of String, pdf
    assert pdf.start_with?("%PDF")
  end
end
