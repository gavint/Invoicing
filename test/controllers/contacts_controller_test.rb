require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "index lists contacts" do
    get contacts_path
    assert_response :success
  end

  test "show displays a contact and their invoices" do
    get contact_path(contacts(:jane))
    assert_response :success
  end

  test "new renders the form" do
    get new_contact_path
    assert_response :success
  end

  test "create with valid params adds a contact" do
    assert_difference("Contact.count", 1) do
      post contacts_path, params: { contact: { name: "New Person", email: "new@example.com" } }
    end
    assert_redirected_to contact_path(Contact.last)
  end

  test "create with invalid params re-renders the form" do
    assert_no_difference("Contact.count") do
      post contacts_path, params: { contact: { name: "", email: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "update changes a contact" do
    patch contact_path(contacts(:bob)), params: { contact: { phone: "555-000-0000" } }
    assert_redirected_to contact_path(contacts(:bob))
    assert_equal "555-000-0000", contacts(:bob).reload.phone
  end

  test "destroy removes a contact with no invoices" do
    assert_difference("Contact.count", -1) do
      delete contact_path(contacts(:bob))
    end
    assert_redirected_to contacts_path
  end

  test "destroy is blocked for a contact with invoices" do
    assert_no_difference("Contact.count") do
      delete contact_path(contacts(:jane))
    end
    assert_redirected_to contacts_path
  end
end
