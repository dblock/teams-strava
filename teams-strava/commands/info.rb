module TeamsStrava
  module Commands
    class Info < Command
      include TeamsStrava::Loggable

      command 'info' do |request|
        logger.info "INFO: #{request}"
        TeamsStrava::INFO
      end
    end
  end
end
