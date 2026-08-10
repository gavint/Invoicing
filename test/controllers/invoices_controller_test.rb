require "test_helper"
require "minitest/mock"

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

  test "mark_paid deactivates an existing Stripe payment link" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    Stripe::PaymentLink.stub :update, ->(*) {} do
      patch mark_paid_invoice_path(invoice)
    end

    assert_nil invoice.reload.stripe_payment_link_id
  end

  test "voiding an invoice deactivates its Stripe payment link" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    called = false
    Stripe::PaymentLink.stub :update, ->(*) { called = true } do
      patch invoice_path(invoice), params: { invoice: { status: "void" } }
    end

    assert called, "expected Stripe::PaymentLink.update to be called"
    assert_nil invoice.reload.stripe_payment_link_id
  end

  test "updating an invoice without voiding it leaves its Stripe payment link alone" do
    invoice = invoices(:draft_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    Stripe::PaymentLink.stub :update, ->(*) { raise "should not be called" } do
      patch invoice_path(invoice), params: { invoice: { notes: "Updated notes" } }
    end

    assert_equal "plink_x", invoice.reload.stripe_payment_link_id
  end

  test "clear_payment_link deactivates and forgets the current link" do
    invoice = invoices(:draft_invoice)
    settings(:default).update!(stripe_secret_key: "sk_test_123")
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    Stripe::PaymentLink.stub :update, ->(*) {} do
      post clear_payment_link_invoice_path(invoice)
    end

    assert_redirected_to edit_invoice_path(invoice)
    invoice.reload
    assert_nil invoice.stripe_payment_link_id
    assert_nil invoice.stripe_payment_link_url
  end

  test "clear_payment_link clears a stale link even if deactivating it on Stripe fails" do
    invoice = invoices(:draft_invoice)
    settings(:default).update!(stripe_secret_key: "sk_test_123")
    invoice.update_columns(stripe_payment_link_id: "plink_from_another_mode", stripe_payment_link_url: "https://buy.stripe.com/test_abc")

    Stripe::PaymentLink.stub :update, ->(*) { raise Stripe::InvalidRequestError.new("No such payment link", "id") } do
      post clear_payment_link_invoice_path(invoice)
    end

    assert_nil invoice.reload.stripe_payment_link_id
  end

  test "regenerate_payment_link deactivates the old link and creates a new one immediately" do
    invoice = invoices(:draft_invoice)
    settings(:default).update!(stripe_secret_key: "sk_test_123")
    invoice.update_columns(stripe_payment_link_id: "plink_old", stripe_payment_link_url: "https://buy.stripe.com/old")
    fake_link = Struct.new(:id, :url).new("plink_new", "https://buy.stripe.com/new")

    deactivated_id = nil
    Stripe::PaymentLink.stub :update, ->(id, *) { deactivated_id = id } do
      Stripe::PaymentLink.stub :create, fake_link do
        post regenerate_payment_link_invoice_path(invoice)
      end
    end

    assert_equal "plink_old", deactivated_id
    assert_redirected_to edit_invoice_path(invoice)
    invoice.reload
    assert_equal "plink_new", invoice.stripe_payment_link_id
    assert_equal "https://buy.stripe.com/new", invoice.stripe_payment_link_url
  end

  test "regenerate_payment_link shows an alert when Stripe isn't configured" do
    invoice = invoices(:draft_invoice)
    settings(:default).update!(stripe_secret_key: nil)

    post regenerate_payment_link_invoice_path(invoice)

    assert_redirected_to edit_invoice_path(invoice)
    follow_redirect!
    assert_match "Couldn&#39;t regenerate", response.body
  end

  test "destroy deletes a void invoice" do
    invoice = invoices(:void_invoice)

    assert_difference("Invoice.count", -1) do
      delete invoice_path(invoice)
    end
    assert_redirected_to invoices_path
  end

  test "destroy refuses to delete a non-void invoice" do
    invoice = invoices(:draft_invoice)

    assert_no_difference("Invoice.count") do
      delete invoice_path(invoice)
    end
    assert_redirected_to invoice_path(invoice)
  end

  test "destroy deactivates a lingering Stripe payment link before deleting a void invoice" do
    invoice = invoices(:void_invoice)
    invoice.update_columns(stripe_payment_link_id: "plink_x", stripe_payment_link_url: "https://buy.stripe.com/x")

    called = false
    Stripe::PaymentLink.stub :update, ->(*) { called = true } do
      delete invoice_path(invoice)
    end

    assert called, "expected Stripe::PaymentLink.update to be called"
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
