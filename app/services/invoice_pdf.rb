# Renders the invoice as a real HTML/CSS document (app/views/invoices/pdf.html.erb,
# wrapped in app/views/layouts/pdf.html.erb) and converts it to PDF bytes using
# Grover, which drives headless Chrome under the hood. Because it's an actual
# browser rendering actual CSS, the template can use anything modern CSS
# supports (flexbox, grid, web fonts, etc.) — no Prawn drawing-DSL limits.
class InvoicePdf
  def initialize(invoice)
    @invoice = invoice
  end

  def render
    html = ApplicationController.render(
      template: "invoices/pdf",
      layout: "pdf",
      assigns: { invoice: @invoice }
    )

    Grover.new(html, format: "A4", print_background: true).to_pdf
  end
end
