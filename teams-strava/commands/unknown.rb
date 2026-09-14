module TeamsStrava
  module Commands
    class Unknown < Command
      include TeamsStrava::Loggable

      command '*' do |request|
        logger.info "UNKNOWN: #{request}"
        "Sorry, I don't understand that command. Type `help` to get help."
      end
    end
  end
end
