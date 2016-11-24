class ApplicationMailer < ActionMailer::Base
  helper :settings
  default from: "Momentum <digital@peoplesmomentum.com>"
  layout 'mailer'
end
