class AdminMailer < ApplicationMailer
  def daily_purchase_report(report_data)
    @report = report_data
    subject = "Reporte de compras del #{report_data[:date]}"

    recipients = User.where(role: [ "admin", "manager" ]).pluck(:email)

    mail(
      to: recipients,
      subject: subject,
      # Asegura que funcione incluso sin templates:
      template_path: "admin_mailer",
      template_name: "daily_purchase_report"
    )
  end
end
