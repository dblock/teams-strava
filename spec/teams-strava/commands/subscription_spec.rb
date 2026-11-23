require 'spec_helper'

describe TeamsStrava::Commands::Subscription do
  include_context 'teams command' do
    let(:args) { ['subscription'] }
  end
  shared_examples_for 'subscription' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end

      it 'displays a message without pricing' do
        expect(response).to eq 'No subscription is required.'
        expect(response).not_to match(/trial|free|\$|subscribe\?/i)
      end
    end

    context 'with subscribed_at' do
      it 'displays subscription info' do
        customer_info = "Subscriber since #{team.subscribed_at.strftime('%B %d, %Y')}."
        expect(response).to eq customer_info
      end
    end

    context 'with a plan' do
      include_context 'stripe mock'
      before do
        stripe_helper.create_plan(id: 'teams-playplay-yearly', amount: 2499, nickname: 'Plan', product: product.id)
      end

      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'teams-playplay-yearly',
            email: 'foo@bar.com'
          )
        end

        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end

        context 'as guild owner' do
          before do
            allow_any_instance_of(User).to receive(:team_owner?).and_return(true)
          end

          it 'displays subscription info without amounts, cards, or payment links' do
            current_period_end = Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y')
            customer_info = [
              "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
              "Subscribed to Plan, will auto-renew on #{current_period_end}."
            ].join("\n")
            expect(response).to eq customer_info
          end

          context 'past due subscription' do
            before do
              subscription = customer.subscriptions.data.first
              subscription['status'] = 'past_due'
              allow(Stripe::Customer).to receive(:retrieve).and_return(customer)
              allow(Stripe::Subscription).to receive(:list).and_return([subscription])
            end

            it 'displays subscription info without asking to pay' do
              customer_info = [
                "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
                "Past Due subscription created #{Time.at(customer.subscriptions.first.created).strftime('%B %d, %Y')} to Plan."
              ].join("\n")
              expect(response).to eq customer_info
            end
          end
        end

        context 'as a regular user' do
          before do
            allow_any_instance_of(User).to receive(:team_owner?).and_return(false)
          end

          it 'displays subscription info' do
            current_period_end = Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y')
            customer_info = [
              "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
              "Subscribed to Plan, will auto-renew on #{current_period_end}."
            ].join("\n")
            expect(response).to eq customer_info
          end
        end
      end
    end
  end

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true, installer_id: 'U007') }

    it_behaves_like 'subscription'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }

      it_behaves_like 'subscription'
    end
  end
end
