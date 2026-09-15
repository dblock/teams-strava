require 'spec_helper'

describe StravaWebhook do
  subject(:webhook) do
    described_class.new
  end

  let(:client) do
    instance_double(Strava::Webhooks::Client)
  end

  before do
    allow(Strava::Webhooks::Client).to receive(:new).and_return(client)
  end

  describe '#ensure!' do
    context 'without an existing subscription' do
      before do
        allow(client).to receive(:push_subscriptions).and_return([])
      end

      it 'creates a subscription' do
        expect(client).to receive(:create_push_subscription).with(
          callback_url: webhook.callback_url,
          verify_token: webhook.verify_token
        ).and_return(double(id: 1, callback_url: webhook.callback_url))
        webhook.ensure!
      end
    end

    context 'with a matching subscription' do
      let(:existing_subscription) do
        double(id: 1, callback_url: webhook.callback_url)
      end

      before do
        allow(client).to receive(:push_subscriptions).and_return([existing_subscription])
      end

      it 'does not create or delete a subscription' do
        expect(client).not_to receive(:create_push_subscription)
        expect(client).not_to receive(:delete_push_subscription)
        webhook.ensure!
      end
    end

    context 'with a stale subscription at a different callback_url' do
      let(:stale_subscription) do
        double(id: 1, callback_url: 'https://old-ngrok-url.ngrok-free.app/api/strava/event')
      end

      before do
        allow(client).to receive(:push_subscriptions).and_return([stale_subscription])
      end

      it 'deletes the stale subscription and creates a new one' do
        expect(client).to receive(:delete_push_subscription).with(id: stale_subscription.id)
        expect(client).to receive(:create_push_subscription).with(
          callback_url: webhook.callback_url,
          verify_token: webhook.verify_token
        ).and_return(double(id: 2, callback_url: webhook.callback_url))
        webhook.ensure!
      end
    end
  end
end
