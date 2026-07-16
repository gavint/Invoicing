require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid with a name and email" do
    contact = Contact.new(name: "Test User", email: "test@example.com")
    assert contact.valid?
  end

  test "invalid without a name" do
    contact = Contact.new(email: "test@example.com")
    assert_not contact.valid?
    assert_includes contact.errors[:name], "can't be blank"
  end

  test "invalid without a properly formatted email" do
    contact = Contact.new(name: "Test User", email: "not-an-email")
    assert_not contact.valid?
    assert_includes contact.errors[:email], "is invalid"
  end

  test "display_name prefers company name when present" do
    assert_equal "Doe Consulting", contacts(:jane).display_name
    assert_equal "Bob Smith", contacts(:bob).display_name
  end

  test "cannot destroy a contact that has invoices" do
    contact = contacts(:jane)
    assert_not contact.destroy
    assert Contact.exists?(contact.id)
  end

  test "can destroy a contact with no invoices" do
    contact = contacts(:bob)
    assert contact.destroy
    assert_not Contact.exists?(contact.id)
  end
end
