require "test_helper"
require "minitest/mock"

class InvoiceMailerTest < ActionMailer::TestCase
  test "invoice_email addresses, subjects, and attaches a PDF" do
    invoice = invoices(:draft_invoice)
    mail = InvoiceMailer.invoice_email(invoice)

    assert_equal [invoice.contact.email], mail.to
    assert_match invoice.invoice_number, mail.subject
    assert_equal 1, mail.attachments.count
    assert mail.attachments.first.content_type.start_with?("application/pdf")
  end

  test "invoice_email includes a pay-online link when Stripe is configured" do
    invoice = invoices(:draft_invoice)
    settings(:default).update!(stripe_secret_key: "sk_test_123")
    fake_link = Struct.new(:id, :url).new("plink_123", "https://buy.stripe.com/test_abc")

    mail = Stripe::PaymentLink.stub :create, fake_link do
      InvoiceMailer.invoice_email(invoice).deliver_now
    end

    assert_match "https://buy.stripe.com/test_abc", mail.html_part&.body.to_s.presence || mail.body.to_s
  end

  test "invoice_email omits the pay-online link when Stripe isn't configured" do
    invoice = invoices(:draft_invoice)
    mail = InvoiceMailer.invoice_email(invoice)

    assert_not_includes (mail.html_part&.body.to_s.presence || mail.body.to_s), "Pay this invoice online"
  end
end
