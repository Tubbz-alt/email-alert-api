require "notifications/client"

module EmailSender
  class Notify
    def call(address:, subject:, body:)
      client.send_email(
        email_address: address,
        template_id: template_id,
        personalisation: {
          subject: subject,
          body: body,
        },
      )
    end

  private

    def client
      @client ||= Notifications::Client.new(api_key)
    end

    def config
      EmailAlertAPI.config.notify
    end

    def api_key
      config.fetch(:api_key)
    end

    def template_id
      config.fetch(:template_id)
    end
  end
end