require "test_helper"
require "minitest/mock"

class StripePaymentLinkTest < ActiveSupport::TestCase
  setup do
    settings(:default).update!(stripe_secret_key: "sk_test_123")
  end

  test "returns nil when Stripe isn't configured" do
    settings(:default).update!(stripe_secret_key: nil)

    assert_nil StripePaymentLink.new(invoices(:draft_invoice)).url
  end

  test "returns nil for a paid invoice" do
    assert_nil StripePaymentLink.new(invoices(:paid_invoice)).url
  end

  test "returns nil for a void invoice" do
    assert_nil StripePaymentLink.new(invoices(:void_invoice)).url
  end

  test "generates and caches a payment link" do
    invoice = invoices(:draft_invoice)
    fake_link = Struct.new(:id, :url).new("plink_123", "https://buy.stripe.com/test_abc")

    url = Stripe::PaymentLink.stub :create, fake_link do
      StripePaymentLink.new(invoice).url
    end

    assert_equal "https://buy.stripe.com/test_abc", url
    invoice.reload
    assert_equal "plink_123", invoice.stripe_payment_link_id
    assert_equal "https://buy.stripe.com/test_abc", invoice.stripe_payment_link_url
  end

  test "does not call Stripe again once a link is cached" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_existing", stripe_payment_link_url: "https://buy.stripe.com/existing")

    url = Stripe::PaymentLink.stub :create, ->(*) { raise "should not be called" } do
      StripePaymentLink.new(invoice).url
    end

    assert_equal "https://buy.stripe.com/existing", url
  end

  test "returns nil instead of raising when Stripe errors" do
    invoice = invoices(:draft_invoice)

    url = Stripe::PaymentLink.stub :create, ->(*) { raise Stripe::AuthenticationError.new("bad key") } do
      StripePaymentLink.new(invoice).url
    end

    assert_nil url
  end

  test "deactivate! marks the link inactive on Stripe and clears the cache" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_existing", stripe_payment_link_url: "https://buy.stripe.com/existing")

    called_with = nil
    Stripe::PaymentLink.stub :update, ->(id, params) { called_with = [ id, params ] } do
      StripePaymentLink.new(invoice).deactivate!
    end

    assert_equal [ "plink_existing", { active: false } ], called_with
    invoice.reload
    assert_nil invoice.stripe_payment_link_id
    assert_nil invoice.stripe_payment_link_url
  end

  test "deactivate! is a no-op when there's no cached link" do
    invoice = invoices(:draft_invoice)
    assert_nil invoice.stripe_payment_link_id

    Stripe::PaymentLink.stub :update, ->(*) { raise "should not be called" } do
      StripePaymentLink.new(invoice).deactivate!
    end

    assert_nil invoice.reload.stripe_payment_link_id
  end
end
