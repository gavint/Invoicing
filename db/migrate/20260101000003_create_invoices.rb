class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.references :contact, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.date :issue_date
      t.date :due_date
      t.string :status, null: false, default: "draft"
      t.text :notes
      t.datetime :paid_at

      t.timestamps
    end
    add_index :invoices, :invoice_number, unique: true
  end
end
