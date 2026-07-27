class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[show edit update destroy mark_paid download_pdf send_email preview_pdf]

  def index
    @show_void = params[:show_void].present?
    @invoices = Invoice.includes(:contact).order(issue_date: :desc)
    if params[:status].present?
      @invoices = @invoices.where(status: params[:status])
    elsif !@show_void
      @invoices = @invoices.where.not(status: "void")
    end
  end

  def show
    @payment_link_url = StripePaymentLink.new(@invoice).url
  end

  def new
    @invoice = Invoice.new(
      issue_date: Date.current,
      due_date: Date.current + 14,
      status: "draft",
      contact_id: params.dig(:invoice, :contact_id)
    )
    3.times { @invoice.invoice_items.build }
  end

  def create
    @invoice = Invoice.new(invoice_params)
    if @invoice.save
      redirect_to @invoice, notice: "Invoice created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @invoice.invoice_items.build if @invoice.invoice_items.empty?
  end

  def update
    status_was = @invoice.status
    if @invoice.update(invoice_params)
      StripePaymentLink.new(@invoice).deactivate! if @invoice.status == "void" && status_was != "void"
      redirect_to @invoice, notice: "Invoice updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: "Invoice deleted."
  end

  def mark_paid
    @invoice.mark_paid!
    StripePaymentLink.new(@invoice).deactivate!
    redirect_to @invoice, notice: "Invoice marked as paid."
  end

  def download_pdf
    pdf = InvoicePdf.new(@invoice).render
    send_data pdf, filename: "invoice-#{@invoice.invoice_number}.pdf", type: "application/pdf", disposition: "inline"
  end

  # Dev-only: renders the same template/layout Grover converts to PDF, but as
  # a plain webpage — so you can use the browser's inspector to live-tweak
  # CSS instead of regenerating a PDF after every change. Not available
  # outside development (see config/routes.rb).
  def preview_pdf
    render template: "invoices/pdf", layout: "pdf"
  end

  def send_email
    InvoiceMailer.invoice_email(@invoice).deliver_now
    @invoice.update(status: "sent") if @invoice.status == "draft"
    redirect_to @invoice, notice: "Invoice emailed to #{@invoice.contact.email}."
  rescue StandardError => e
    redirect_to @invoice, alert: "Couldn't send email: #{e.message}"
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:contact_id, :issue_date, :due_date, :status, :notes,
      invoice_items_attributes: %i[id description quantity unit_price _destroy])
  end
end
