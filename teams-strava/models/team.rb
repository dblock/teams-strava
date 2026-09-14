class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at'].freeze

  scope :active, -> { where(active: true) }

  field :team_id, type: String
  field :team_name, type: String
  field :tenant_id, type: String
  field :conversation_id, type: String
  field :service_url, type: String

  field :installer_id, type: String
  field :installer_name, type: String

  field :active, type: Mongoid::Boolean, default: true

  field :api, type: Boolean, default: false

  field :units, type: String, default: 'mi'
  validates_inclusion_of :units, in: %w[mi km both]

  field :temperature, type: String, default: 'f'
  validates_inclusion_of :temperature, in: %w[f c both]

  field :activity_fields, type: Array, default: ['Default']
  validates :activity_fields, array: { presence: true, inclusion: { in: ActivityFields.values } }

  field :maps, type: String, default: 'full'
  validates_inclusion_of :maps, in: MapTypes.values

  field :default_leaderboard, type: String

  field :retention, type: Integer, default: 30 * 24 * 60 * 60
  before_validation :validate_retention

  field :timezone, type: String, default: 'auto'
  validates_presence_of :timezone

  field :max_activities_per_user_per_day, type: Integer
  before_validation :validate_max_activities_per_user_per_day

  field :max_activities_per_channel_per_day, type: Integer
  before_validation :validate_max_activities_per_channel_per_day

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime
  field :subscription_expired_at, type: DateTime

  field :trial_informed_at, type: DateTime
  field :past_due_informed_at, type: DateTime

  scope :api, -> { where(api: true) }
  scope :striped, -> { where(subscribed: true, :stripe_customer_id.ne => nil) }
  scope :trials, -> { where(subscribed: false) }

  has_many :users, dependent: :destroy
  has_many :activities
  has_many :channels, dependent: :destroy

  validates_uniqueness_of :team_id
  validates_presence_of :team_id
  validates_presence_of :tenant_id
  validates_presence_of :conversation_id
  validates_presence_of :service_url

  before_validation :update_subscribed_at
  before_validation :update_subscription_expired_at
  after_update :subscribed!
  after_save :activated!
  before_destroy :destroy_subscribed_team

  def self.install_or_update!(ctx)
    activity = ctx.activity
    team_info = activity.channel_data.team
    return unless team_info&.id

    attrs = {
      team_name: team_info.name,
      tenant_id: activity.channel_data.tenant&.id || activity.conversation.tenant_id,
      conversation_id: activity.conversation.id,
      service_url: activity.service_url,
      installer_id: activity.from.aad_object_id || activity.from.id,
      installer_name: activity.from.name,
      active: true
    }

    team = where(team_id: team_info.id).first
    if team
      team.update_attributes!(attrs)
    else
      team = create!(attrs.merge(team_id: team_info.id))
      TeamsStrava::Service.instance.create!(team)
    end
    team
  end

  def self.find_by_activity!(activity)
    team_id = activity.channel_data.team&.id
    raise TeamsStrava::Error, 'Strata works best in a regular Teams channel.' unless team_id

    where(team_id:).first || raise(TeamsStrava::Error, "Missing team with team_id=#{team_id}.")
  end

  def update_info!
    team_info = TeamsStrava::Bot.instance.info(team_id)
    update_attributes!(team_name: team_info.name) if team_info&.name
  rescue StandardError => e
    logger.warn "Error updating information for team #{self}, #{e.message}."
    NewRelic::Agent.notice_error(e, custom_params: { team: to_s })
  end

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def to_s
    {
      _id:,
      team_id:,
      team_name:
    }.map { |k, v|
      "#{k}=#{v}" if v
    }.compact.join(', ')
  end

  def ping!
    # raise NotImplementedError
  end

  def ping_if_active!
    return unless active?

    ping!
  rescue StandardError => e
    logger.warn "Active team #{self} ping, #{e.message}, deactivating."
    deactivate!
  end

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  def units_s
    case units
    when 'mi'
      'miles, feet, and yards'
    when 'km'
      'kilometers and meters'
    when 'both'
      'both units'
    else
      raise ArgumentError
    end
  end

  def temperature_s
    { 'f' => 'degrees Fahrenheit', 'c' => 'degrees Celsius', 'both' => 'degrees Fahrenheit and Celsius' }[temperature] || raise(ArgumentError)
  end

  def maps_s
    case maps
    when 'off'
      'not displayed'
    when 'full'
      'displayed in full'
    when 'thumb'
      'displayed as thumbnails'
    else
      raise ArgumentError
    end
  end

  def activity_fields_s
    case activity_fields
    when ['All']
      'all displayed if available'
    when ['Default']
      'set to default'
    when ['None']
      'not displayed'
    else
      activity_fields.and
    end
  end

  def default_leaderboard_s
    default_leaderboard || 'distance'
  end

  def asleep?(dt = 2.weeks)
    return false unless subscription_expired?

    time_limit = Time.now - dt
    created_at <= time_limit
  end

  def team_owners
    [
      installer_id
    ].compact.uniq
  end

  # sends a 1:1 message to the team's installer(s)
  def inform_team_owner!(message)
    return unless installer_id

    team_owners.map { |id|
      begin
        sent = TeamsStrava::Bot.instance.send_dm(id, tenant_id, message)

        {
          activity_id: sent.id,
          conversation_id: sent.conversation_id
        }
      rescue TeamsStrava::Error => e
        logger.warn "Error DMing team owner #{id} for #{self}: #{e.message}"
        nil
      end
    }.compact
  end

  def inform_system!(message)
    return unless conversation_id

    sent = TeamsStrava::Bot.instance.send_message(conversation_id, service_url, message)

    {
      activity_id: sent.id,
      conversation_id: sent.conversation_id
    }
  rescue TeamsStrava::Error => e
    logger.warn "Error posting to the team channel for #{self}: #{e.message}"
    nil
  end

  def inform_everyone!(message)
    inform_system!(message)
    inform_team_owner!(message)
  end

  def subscription_info(team_owner = true)
    subscription_info = []
    if stripe_subcriptions&.any?
      subscription_info << stripe_customer_text
      subscription_info.concat(stripe_customer_subscriptions_info)
      if team_owner
        subscription_info.concat(stripe_customer_invoices_info)
        subscription_info.concat(stripe_customer_sources_info)
        subscription_info << update_cc_text
      end
    elsif subscribed && subscribed_at
      subscription_info << subscriber_text
    else
      subscription_info << trial_message
    end
    subscription_info.compact.join("\n")
  end

  def subscription_expired!
    return unless subscription_expired?
    return if subscription_expired_at

    inform_everyone!(subscribe_text)
    update_attributes!(subscription_expired_at: Time.now.utc)
  end

  def subscription_expired?
    return false if subscribed?

    time_limit = Time.now - 2.weeks
    created_at < time_limit
  end

  def update_cc_text
    "Update your credit card info at #{TeamsStrava::Service.url}/update_cc?team_id=#{id}."
  end

  def subscribed_text
    <<~EOS.freeze
      Your team has been subscribed. Proceeds go to NYRR. Thank you!
      Follow https://twitter.com/playplayio for news and updates.
    EOS
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?

    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?

    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      if remaining_trial_days.zero?
        'Your trial subscription has expired.'
      else
        "Your trial subscription expires in #{remaining_trial_days} day#{'s' unless remaining_trial_days == 1}."
      end,
      subscribe_text
    ].join(' ')
  end

  def inform_trial!
    return if subscribed? || subscription_expired?
    return if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)

    inform_everyone!(trial_message)
    update_attributes!(trial_informed_at: Time.now.utc)
  end

  def stripe_customer
    return unless stripe_customer_id

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def stripe_customer_text
    "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
  end

  def subscriber_text
    return unless subscribed_at

    "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}."
  end

  def subscribe_text
    "Subscribe your team for $19.99 a year at #{TeamsStrava::Service.url}/subscribe?team_id=#{id} to continue receiving Strava activities in Teams. Proceeds go to NYRR."
  end

  def stripe_customer_subscriptions_info
    Stripe::Subscription.list(customer: stripe_customer.id).map do |subscription|
      amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
      current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
      plan_name = subscription.plan.nickname
      if subscription.status == 'active'
        [
          "Subscribed to #{plan_name} (#{amount}), will#{' not' if subscription.cancel_at_period_end} auto-renew on #{current_period_end}."
        ].compact.join("\n")
      else
        "#{subscription.status.titleize} subscription created #{Time.at(subscription.created).strftime('%B %d, %Y')} to #{plan_name} (#{amount})."
      end
    end
  end

  def stripe_customer_invoices_info
    Stripe::Invoice.list(customer: stripe_customer.id).map do |invoice|
      amount = ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)
      "Invoice for #{amount} on #{Time.at(invoice.created).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
    end
  end

  def stripe_customer_sources_info
    Stripe::Customer.list_sources(stripe_customer.id).map do |source|
      "On file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
    end
  end

  def stripe_subcriptions
    return unless stripe_customer

    Stripe::Subscription.list(customer: stripe_customer.id)
  end

  def active_stripe_subscription?
    !active_stripe_subscription.nil?
  end

  def active_stripe_subscription
    return unless stripe_customer

    Stripe::Subscription.list(customer: stripe_customer.id).detect do |subscription|
      subscription.status == 'active'
    end
  end

  def stats(options = {})
    TeamStats.new(self, options)
  end

  def self.purge!(dt = 2.weeks.ago)
    # destroy teams inactive for two weeks
    Team.where(active: false, :updated_at.lte => dt).each do |team|
      logger.info "Destroying #{team}, inactive since #{team.updated_at}."
      team.destroy
    rescue StandardError => e
      logger.warn "Error destroying #{team}, #{e.message}."
    end
  end

  def leaderboard(options = {})
    TeamLeaderboard.new(self, options)
  end

  def check_access!
    team_info = TeamsStrava::Bot.instance.info(team_id)
    logger.info "Checked access for _id=#{_id}, team=#{team_info&.name}, id=#{team_info&.id}."
  rescue TeamsStrava::Error => e
    case e.message
    when /404|403/
      logger.info "Deactivating #{self}, #{e}"
      deactivate!
    else
      raise
    end
  end

  def prune_activities!
    total = 0
    activities.where(:updated_at.lt => prune_before_updated_at).each do |activity|
      logger.info "Pruning #{self}, #{activity.id}."
      activity.destroy!
      total += 1
    end
    total
  end

  def retention_s
    ChronicDuration.output(retention, format: :long)
  end

  def tzone
    if timezone == 'auto'
      detect_timezone || ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')
    else
      ActiveSupport::TimeZone.new(timezone)
    end
  end

  def timezone_s
    if timezone == 'auto'
      "auto (#{tzone.name})"
    else
      tzone.to_s
    end
  end

  def max_activities_per_user_per_day_s
    max_activities_per_user_per_day ? "#{max_activities_per_user_per_day} per day" : 'unlimited'
  end

  def max_activities_per_channel_per_day_s
    max_activities_per_channel_per_day ? "#{max_activities_per_channel_per_day} per day" : 'unlimited'
  end

  def set_channel!(channel_id, channel_name, attrs = {})
    c = channels.find_or_initialize_by(channel_id: channel_id)
    c.assign_attributes(attrs.merge(channel_name: channel_name))
    c.save!
    c
  end

  def channel_activity_types_for(channel_id)
    c = channels.find_by(channel_id: channel_id)
    return [] if c.nil? || c.activity_types.blank?

    c.activity_types
  end

  def channel_activity_types_s(channel_id)
    c = channels.find_by(channel_id: channel_id)
    c&.activity_types_s || 'all'
  end

  def channel_maps_for(channel_id)
    return maps unless channel_id

    c = channels.find_by(channel_id: channel_id)
    c&.maps || maps
  end

  def channel_maps_s(channel_id)
    c = channels.find_by(channel_id: channel_id)
    c&.maps_s || maps_s
  end

  def channel_units_for(channel_id)
    return units unless channel_id

    c = channels.find_by(channel_id: channel_id)
    c&.units || units
  end

  def channel_units_s(channel_id)
    c = channels.find_by(channel_id: channel_id)
    c&.units_s || units_s
  end

  def channel_temperature_for(channel_id)
    return temperature unless channel_id

    c = channels.find_by(channel_id: channel_id)
    c&.temperature || temperature
  end

  def channel_temperature_s(channel_id)
    c = channels.find_by(channel_id: channel_id)
    c&.temperature_s || temperature_s
  end

  def channel_activity_fields_for(channel_id)
    return activity_fields unless channel_id

    c = channels.find_by(channel_id: channel_id)
    c&.activity_fields || activity_fields
  end

  def channel_activity_fields_s(channel_id)
    c = channels.find_by(channel_id: channel_id)
    c&.activity_fields_s || activity_fields_s
  end

  def channel_max_activities_per_user_per_day_for(channel_id)
    return max_activities_per_user_per_day unless channel_id

    c = channels.find_by(channel_id: channel_id)
    c&.max_activities_per_user_per_day || max_activities_per_user_per_day
  end

  def channel_max_activities_per_user_per_day_s(channel_id)
    c = channels.find_by(channel_id: channel_id)
    c&.max_activities_per_user_per_day_s || max_activities_per_user_per_day_s
  end

  def now
    Time.now.utc.in_time_zone(tzone)
  end

  def detect_timezone
    timezones = UserActivity.where(team_id: id, :timezone.ne => nil)
                            .desc(:start_date)
                            .limit(50)
                            .pluck(:timezone)
    return nil if timezones.empty?

    most_common = timezones.tally.max_by { |_, count| count }.first
    iana_name = most_common.split(' ', 2).last
    ActiveSupport::TimeZone.all.find { |tz| tz.tzinfo.identifier == iana_name }
  end

  private

  def validate_retention
    return if retention.nil?

    errors.add(:team, 'Retention must be at least 24 hours.') if retention < 24 * 60 * 60
    errors.add(:team, 'Retention cannot exceed 6 months.') if retention > 6 * 30 * 24 * 60 * 60
  end

  def validate_max_activities_per_user_per_day
    return if max_activities_per_user_per_day.nil?

    errors.add(:team, 'Max activities per user per day must be at least 1.') if max_activities_per_user_per_day < 1
  end

  def validate_max_activities_per_channel_per_day
    return if max_activities_per_channel_per_day.nil?

    errors.add(:team, 'Max activities per channel per day must be at least 1.') if max_activities_per_channel_per_day < 1
  end

  def prune_before_updated_at
    Time.now - (retention || (30 * 24 * 60 * 60))
  end

  def destroy_subscribed_team
    raise 'cannot destroy a subscribed team' if subscribed?
  end

  def subscribed!
    return unless subscribed? && (subscribed_changed? || saved_change_to_subscribed?)

    inform_everyone!(subscribed_text)
  end

  def activated_text
    <<~EOS
      Welcome to Strata!
      @mention me and type *connect* to connect your Strava account to a Teams channel.
    EOS
  end

  def activated!
    return unless active? && (active_changed? || saved_change_to_active?)

    inform_activated!
    update_info!
  end

  def inform_activated!
    inform_system!(activated_text)
  end

  def update_subscribed_at
    return unless subscribed? && (subscribed_changed? || saved_change_to_subscribed?)

    self.subscribed_at = subscribed? ? DateTime.now.utc : nil
  end

  def update_subscription_expired_at
    return unless subscribed? && subscription_expired_at?

    self.subscription_expired_at = nil
  end
end
