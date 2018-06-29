class EmailArchivePresenter
  # This is expected to be called with a JSON representation of a record
  # returned from EmailArchiveQuery
  def self.for_s3(*args)
    new.for_s3(*args)
  end

  def for_s3(record, archived_at)
    {
      archived_at: archived_at.utc.to_s(:db),
      content_change: build_content_change(record),
      created_at: record.fetch("created_at").utc.to_s(:db),
      finished_sending_at: record.fetch("finished_sending_at").utc.to_s(:db),
      id: record.fetch("id"),
      sent: record.fetch("sent"),
      subject: record.fetch("subject"),
      subscriber_id: record.fetch("subscriber_id"),
    }
  end

  def self.for_db(*args)
    new.for_db(*args)
  end

  def for_db(record, archived_at, exported_at = nil)
    {
      archived_at: archived_at,
      content_change: build_content_change(record),
      created_at: record.fetch("created_at"),
      exported_at: exported_at,
      finished_sending_at: record.fetch("finished_sending_at"),
      id: record.fetch("id"),
      sent: record.fetch("sent"),
      subject: record.fetch("subject"),
      subscriber_id: record.fetch("subscriber_id"),
    }
  end

  private_class_method :new

private

  def build_content_change(record)
    return if record.fetch("content_change_ids").empty?

    if record.fetch("digest_run_ids").count > 1
      error = "Email with id: #{record['id']} is associated with "\
        "multiple digest runs: #{record['digest_run_ids'].join(', ')}"
      GovukError.notify(error)
    end

    {
      content_change_ids: record.fetch("content_change_ids"),
      digest_run_id: record.fetch("digest_run_ids").first,
      subscription_ids: record.fetch("subscription_ids"),
    }
  end
end
