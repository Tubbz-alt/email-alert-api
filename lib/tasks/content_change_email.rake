namespace :report do
  desc <<~DESCRIPTION
    Produce a report on sent, pending and failed emails for given content change id or ids
    At least one ContentChange id must be given. Usage:
    - report:content_change_email_status_count[id_1]
    - report:content_change_email_status_count[id_1,id_2,id_n]
  DESCRIPTION
  task content_change_email_status_count: :environment do |_t, args|
    if args.extras.present?
      content_changes = ContentChange.where(id: args.extras)
      Reports::ContentChangeEmailStatusCount.call(content_changes)
    else
      puts "At least one ContentChange id must be given. Usage:"
      puts "- report:content_change_email_status_count[id_1]"
      puts "- report:content_change_email_status_count[id_1,id_2,id_n]"
    end
  end

  desc <<~DESCRIPTION
    Produce a report on failed emails for given content change id or ids
    At least one ContentChange id must be given. Usage:
    - report:content_change_failed_emails[id_1]
    - report:content_change_failed_emails[id_1,id_2,id_n]
  DESCRIPTION
  task content_change_failed_emails: :environment do |_t, args|
    if args.extras.present?
      content_changes = ContentChange.where(id: args.extras)
      Reports::ContentChangeEmailFailures.call(content_changes)
    else
      puts "At least one ContentChange id must be given. Usage:"
      puts "- report:content_change_failed_emails[id_1]"
      puts "- report:content_change_failed_emails[id_1,id_2,id_n]"
    end
  end

  desc <<~DESCRIPTION
    For a ContentChange Id, find any unsent emails and queue
    them for delivery on the immediate high queue
  DESCRIPTION
  task :force_send_emails, %i[content_change_id] => :environment do |_t, args|
    raise ArgumentError.new("Missing content change id") unless args[:content_change_id].present?

    ImmediateDelivery::QueueUnsentEmailsForContentChange.call(content_change_id: args[:content_change_id])
  end
end
