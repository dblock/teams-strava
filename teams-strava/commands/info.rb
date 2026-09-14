module TeamsStrava
  module Commands
    class Info < Command
      include TeamsStrava::Loggable

      command 'info' do |request|
        logger.info "INFO: #{request}"
        [
          TeamsStrava::INFO,
          request.team.reload.subscribed? ? nil : request.team.trial_message
        ].compact.join("\n")
      end
    end
  end
end
