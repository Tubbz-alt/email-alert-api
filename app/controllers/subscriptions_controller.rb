class SubscriptionsController < ApplicationController
  def create
    return render json: { id: 0 }, status: :created if smoke_test_address?

    [subscription, status] = SubscriptionBuilderService.new(subscriber, subscriber_list, frequency, current_user.uid).call
    render json: { id: subscription.id }, status: status
  end

  def show
    subscription = Subscription.find(subscription_params.require(:id))
    render json: { subscription: subscription }
  end

  def update
    existing_subscription = nil
    subscription = nil

    Subscription.transaction do
      existing_subscription = Subscription.active.lock.find(
        subscription_params.require(:id)
      )

      existing_subscription.end(reason: :frequency_changed)

      begin
        subscription = Subscription.create!(
          subscriber: existing_subscription.subscriber,
          subscriber_list: existing_subscription.subscriber_list,
          frequency: frequency,
          signon_user_uid: current_user.uid,
          source: :frequency_changed
        )
      rescue ArgumentError
        # This happens if a frequency is provided that isn't included
        # in the enum which is in the Subscription model
        raise ActiveRecord::RecordInvalid
      end
    end

    render json: { subscription: subscription }, status: :ok
  end

private

  def smoke_test_address?
    address.end_with?("@notifications.service.gov.uk")
  end

  def subscriber
    @subscriber ||= begin
                      found = Subscriber.find_by_address(address)
                      found || Subscriber.create!(
                        address: address,
                        signon_user_uid: current_user.uid,
                      )
                    end
  end

  def address
    subscription_params.require(:address)
  end

  def subscriber_list
    @subscriber_lists ||= begin
      subscriber_list = SubscriberList.find_by(slug: subscriber_list_slug)
      if subscriber_list.nil?
        subscriber_list = OrJoinedSubscriberList.find(slug: subscriber_list_slug)
      end
      subscriber_list
    end
  end

  def subscriber_list_slug
    subscription_params[:subscribable_id] || subscription_params.require(:subscriber_list_id)
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately").to_sym
  end

  def subscription_params
    params.permit(:id, :address, :subscribable_id, :subscriber_list_id, :frequency)
  end
end
