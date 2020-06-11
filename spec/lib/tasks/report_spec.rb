require "rails_helper"

RSpec.describe "report" do
  describe "matched_content_changes" do
    it "outputs a CSV of matched content changes" do
      expect { Rake::Task["report:matched_content_changes"].invoke }
        .to output.to_stdout
    end
  end

  describe "content_change_email_status_count" do
    it "outputs a report of content change email statuses" do
      content_change = create :content_change

      expect { Rake::Task["report:content_change_email_status_count"].invoke(content_change.id.to_s) }
        .to output.to_stdout
    end
  end

  describe "content_change_failed_emails" do
    it "outputs a report of failed content change emails" do
      content_change = create :content_change

      expect { Rake::Task["report:content_change_failed_emails"].invoke(content_change.id.to_s) }
        .to output.to_stdout
    end
  end

  describe "count_subscribers_report" do
    it "outputs a report of subscribers for a list" do
      subscriber_list = create :subscriber_list

      expect { Rake::Task["report:count_subscribers"].invoke(subscriber_list.slug) }
        .to output.to_stdout
    end
  end

  describe "count_subscribers_on_report" do
    it "outputs a report of subscribers for a list on a date" do
      subscriber_list = create :subscriber_list

      expect { Rake::Task["report:count_subscribers_on"].invoke("2019-08-01", subscriber_list.slug) }
        .to output.to_stdout
    end
  end

  describe "find_delivery_attempts" do
    it "outputs a report of delivery attempts over a date range" do
      create :delivered_delivery_attempt, created_at: "2019-08-03"

      expect { Rake::Task["report:find_delivery_attempts"].invoke("2019-08-01", "2019-08-07") }
        .to output.to_stdout
    end
  end
end
