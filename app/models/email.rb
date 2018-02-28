class Email < ApplicationRecord
  has_many :delivery_attempts

  scope :archivable, lambda {
    where(archived_at: nil).where.not(finished_sending_at: nil)
  }

  validates :address, :subject, :body, presence: true

  # Mark an email to indicate the process of sending it is complete
  def finish_sending(delivery_attempt)
    raise ArgumentError, "DeliveryAttempt for different email" if delivery_attempt.email_id != id
    # @FIXME We should use a timestamp from the provider if possible
    update!(finished_sending_at: delivery_attempt.updated_at)
  end
end
