class DashboardController < ApplicationController
  def index
    @outstanding_invoices = Invoice.where(status: %w[draft sent]).includes(:contact).order(:due_date)
    @outstanding_total = @outstanding_invoices.sum(&:total)
    @overdue_count = @outstanding_invoices.count(&:overdue?)
  end
end
