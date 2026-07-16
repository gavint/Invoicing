class InvoiceMailer < ApplicationMailer
  def invoice_email(invoice)
    @invoice = invoice
    @contact = invoice.contact
    @settings = Setting.instance

    attachments["invoice-#{@invoice.invoice_number}.pdf"] = InvoicePdf.new(@invoice).render

    mail(
      to: @contact.email,
      from: "#{@settings.company_name} <#{@settings.company_email}>".strip,
      subject: "Invoice #{@invoice.invoice_number} from #{@settings.company_name}",
      delivery_method_options: smtp_options
    )
  end

  private

  def smtp_options
    {
      address: @settings.smtp_address,
      port: @settings.smtp_port.presence || 587,
      user_name: @settings.smtp_username,
      password: @settings.smtp_password,
      authentication: "plain",
      enable_starttls_auto: true
    }
  end
end
