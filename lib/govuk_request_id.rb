class GovukRequestId
  class << self
    def insert(body)
      return body unless body.present?

      if body =~ /^</
        body += govuk_request_id_html
      end

      body
    end

  private

    def govuk_request_id_html
      %Q(<span data-govuk-request-id="#{govuk_request_id}"></span>)
    end

    def govuk_request_id
      GdsApi::GovukHeaders.headers[:govuk_request_id]
    end
  end
end
