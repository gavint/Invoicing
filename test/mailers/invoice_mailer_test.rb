require "test_helper"

class InvoiceMailerTest < ActionMailer::TestCase
  test "invoice_email addresses, subjects, and attaches a PDF" do
    invoice = invoices(:draft_invoice)
    mail = InvoiceMailer.invoice_email(invoice)

    assert_equal [invoice.contact.email], mail.to
    assert_match invoice.invoice_number, mail.subject
    assert_equal 1, mail.attachments.count
    assert mail.attachments.first.content_type.start_with?("application/pdf")
  end
end
