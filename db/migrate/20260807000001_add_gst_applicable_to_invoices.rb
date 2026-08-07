class AddGstApplicableToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :gst_applicable, :boolean, default: true, null: false
  end
end
