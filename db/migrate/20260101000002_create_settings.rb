class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.string :company_name
      t.string :company_email
      t.string :company_phone
      t.string :company_address_line1
      t.string :company_address_line2
      t.string :company_city
      t.string :company_state
      t.string :company_zip
      t.string :company_country
      t.text :invoice_footer_note
      t.string :smtp_address
      t.integer :smtp_port
      t.string :smtp_username
      t.string :smtp_password

      t.timestamps
    end
  end
end
