require "prawn"
require "prawn/table"

class InvoicePdf
  def initialize(invoice)
    @invoice = invoice
    @contact = invoice.contact
    @settings = Setting.instance
  end

  def render
    Prawn::Document.new(margin: 50) do |pdf|
      pdf.text @settings.company_name.to_s, size: 20, style: :bold
      pdf.text company_address_lines.join(", ") if company_address_lines.any?
      pdf.text @settings.company_email.to_s
      pdf.text @settings.company_phone.to_s if @settings.company_phone.present?
      pdf.move_down 20

      pdf.text "INVOICE ##{@invoice.invoice_number}", size: 16, style: :bold
      pdf.text "Issue date: #{@invoice.issue_date&.strftime('%B %d, %Y')}"
      pdf.text "Due date: #{@invoice.due_date&.strftime('%B %d, %Y')}"
      pdf.move_down 10

      pdf.text "Bill to:", style: :bold
      pdf.text @contact.display_name
      pdf.text contact_address_lines.join(", ") if contact_address_lines.any?
      pdf.text @contact.email.to_s
      pdf.move_down 20

      rows = [["Description", "Qty", "Unit Price", "Total"]]
      @invoice.invoice_items.each do |item|
        rows << [
          item.description,
          item.quantity.to_s,
          currency(item.unit_price),
          currency(item.line_total)
        ]
      end

      pdf.table(rows, header: true, width: pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = "EEEEEE"
        columns(1..3).align = :right
      end

      pdf.move_down 10
      pdf.text "Total: #{currency(@invoice.total)}", size: 14, style: :bold, align: :right

      if @invoice.notes.present?
        pdf.move_down 20
        pdf.text "Notes:", style: :bold
        pdf.text @invoice.notes
      end

      if @settings.invoice_footer_note.present?
        pdf.move_down 30
        pdf.text @settings.invoice_footer_note
      end
    end.render
  end

  private

  def company_address_lines
    [
      @settings.company_address_line1,
      @settings.company_address_line2,
      [@settings.company_city, @settings.company_state, @settings.company_zip].compact_blank.join(", "),
      @settings.company_country
    ].compact_blank
  end

  def contact_address_lines
    [
      @contact.billing_address_line1,
      @contact.billing_address_line2,
      [@contact.billing_city, @contact.billing_state, @contact.billing_zip].compact_blank.join(", "),
      @contact.billing_country
    ].compact_blank
  end

  def currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount)
  end
end
