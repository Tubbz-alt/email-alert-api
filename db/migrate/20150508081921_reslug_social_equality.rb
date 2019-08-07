# rubocop:disable Lint/UnreachableCode

class ReslugSocialEquality < ActiveRecord::Migration[4.2]
  def up
    return

    list = SubscriberListQuery.where_tags_equal(policies: %w[social-equality]).first

    if list
      list.update(tags: {
        policies: %w[equality]
      })
      list.reload
      puts %{Reslugged "social-equality" to #{list.tags[:policies]}}
    else
      puts %{Could not find a subscriber list with the policy tag "social-equality"}
    end
  end

  def down
    list = SubscriberListQuery.where_tags_equal(policies: %w[equality]).first

    if list
      list.update(tags: {
        policies: %w[social-equality]
      })
      list.reload
      puts %{Reslugged "equality" to #{list.tags[:policies]}}
    else
      puts %{Could not find a subscriber list with the policy tag "equality"}
    end
  end
end

# rubocop:enable Lint/UnreachableCode
