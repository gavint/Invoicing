# Invoices are sent via SMTP using the credentials entered on the in-app
# Settings screen (see InvoiceMailer). This just turns SMTP delivery on;
# the actual server/username/password are supplied per-email at send time.
#
# In the test environment we deliberately leave Rails' default :test delivery
# method in place, so specs can assert against ActionMailer::Base.deliveries
# instead of trying to hit a real SMTP server.
unless Rails.env.test?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.perform_deliveries = true
  Rails.application.config.action_mailer.raise_delivery_errors = true
end

Rails.application.config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
