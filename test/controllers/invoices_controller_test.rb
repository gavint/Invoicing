require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  test "index lists invoices" do
    get invoices_path
    assert_response :success
  end

  test "index filters by status" do
    get invoices_path(status: "sent")
    assert_response :success
    assert_match invoices(:overdue_invoice).invoice_number, response.body
  end

  test "index excludes void invoices by default" do
    get invoices_path
    assert_response :success
    assert_no_match invoices(:void_invoice).invoice_number, response.body
  end

  test "index includes void invoices when show_void is checked" do
    get invoices_path(show_void: "1")
    assert_response :success
    assert_match invoices(:void_invoice).invoice_number, response.body
  end

  test "show displays an invoice" do
    get invoice_path(invoices(:draft_invoice))
    assert_response :success
  end

  test "new renders the form" do
    get new_invoice_path
    assert_response :success
  end

  test "create builds an invoice with line items" do
    assert_difference("Invoice.count", 1) do
      post invoices_path, params: {
        invoice: {
          contact_id: contacts(:jane).id,
          issue_date: Date.current,
          due_date: Date.current + 10,
          status: "draft",
          invoice_items_attributes: {
            "0" => { description: "New work", quantity: 2, unit_price: 100 }
          }
        }
      }
    end
    assert_equal 1, Invoice.last.invoice_items.count
  end

  test "mark_paid updates status" do
    invoice = invoices(:draft_invoice)
    patch mark_paid_invoice_path(invoice)
    assert_redirected_to invoice_path(invoice)
    assert_equal "paid", invoice.reload.status
  end

  test "download_pdf returns a PDF" do
    get download_pdf_invoice_path(invoices(:draft_invoice))
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "send_email delivers the invoice and marks a draft as sent" do
    invoice = invoices(:draft_invoice)
    assert_emails 1 do
      post send_email_invoice_path(invoice)
    end
    assert_equal "sent", invoice.reload.status
    assert_redirected_to invoice_path(invoice)
  end
end
