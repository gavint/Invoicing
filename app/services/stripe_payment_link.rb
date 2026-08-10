# Generates a Stripe Payment Link for an invoice's current total and caches
# the result on the invoice (stripe_payment_link_id/url), so repeated calls -
# re-downloading the PDF, re-sending the email - don't create duplicate links
# in the Stripe dashboard. The cache is cleared whenever the invoice's total
# could have changed (see the clear_stale_payment_link callbacks on Invoice
# and InvoiceItem), so the link always reflects Invoice#total, GST included.
class StripePaymentLink
  def initialize(invoice)
    @invoice = invoice
    @settings = Setting.instance
  end

  # Returns the invoice's payment link URL, generating and caching one via
  # the Stripe API if none exists yet. Returns nil if Stripe isn't configured
  # or the API call fails, so PDF/email generation is never blocked by it.
  def url
    return nil unless @settings.stripe_configured?
    return nil if %w[paid void].include?(@invoice.status)
    return @invoice.stripe_payment_link_url if @invoice.stripe_payment_link_url.present?

    generate
  rescue Stripe::StripeError => e
    Rails.logger.warn("Stripe payment link generation failed for invoice #{@invoice.id}: #{e.message}")
    nil
  end

  # Marks the invoice's Stripe payment link inactive (e.g. when voiding an
  # invoice) so it can no longer be paid, and clears the local cache. The
  # local cache is always cleared, even if the Stripe call fails - e.g. a
  # link created under a different Stripe key (test vs live) won't exist
  # under the current one, but it should still stop being served locally.
  def deactivate!
    attempt_remote_deactivation
    @invoice.update_columns(stripe_payment_link_id: nil, stripe_payment_link_url: nil)
  end

  private

  def attempt_remote_deactivation
    return if @invoice.stripe_payment_link_id.blank?

    Stripe.api_key = @settings.stripe_secret_key
    Stripe::PaymentLink.update(@invoice.stripe_payment_link_id, active: false)
  rescue Stripe::StripeError => e
    Rails.logger.warn("Stripe payment link deactivation failed for invoice #{@invoice.id}: #{e.message}")
  end

  def generate
    Stripe.api_key = @settings.stripe_secret_key

    link = Stripe::PaymentLink.create(
      line_items: [ {
        price_data: {
          currency: "aud",
          product_data: { name: "Invoice #{@invoice.invoice_number}" },
          unit_amount: amount_in_cents
        },
        quantity: 1
      } ]
    )

    @invoice.update_columns(stripe_payment_link_id: link.id, stripe_payment_link_url: link.url)
    link.url
  end

  def amount_in_cents
    (@invoice.total * 100).round
  end
end
