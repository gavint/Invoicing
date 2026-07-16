# Seed data: a default settings row plus one sample contact and invoice so
# you can see how everything looks before entering your own data.

Setting.instance

contact = Contact.find_or_create_by!(email: "jane@example.com") do |c|
  c.name = "Jane Doe"
  c.company_name = "Doe Consulting"
  c.phone = "555-123-4567"
  c.billing_address_line1 = "123 Main St"
  c.billing_city = "Springfield"
  c.billing_state = "IL"
  c.billing_zip = "62704"
  c.billing_country = "USA"
end

if contact.invoices.none?
  invoice = contact.invoices.create!(
    issue_date: Date.current,
    due_date: Date.current + 14,
    status: "draft",
    notes: "Sample invoice — feel free to delete this."
  )
  invoice.invoice_items.create!(description: "Consulting services", quantity: 10, unit_price: 125)
  invoice.invoice_items.create!(description: "Project setup fee", quantity: 1, unit_price: 250)
end

puts "Seeded #{Contact.count} contact(s) and #{Invoice.count} invoice(s)."
