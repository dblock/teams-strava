module TeamsStrava
  module Commands
    class << self
      def invoke!(request)
        result = command_classes.detect do |k|
          rc = k.invoke!(request)
          break rc if rc
        end
        result || TeamsStrava::Commands::Unknown.invoke!(request)
      end

      def command_classes
        Command.command_classes.reject { |k| k == Unknown }
      end
    end

    # Base class for a named text command (e.g. "connect", "set units mi").
    # Subclasses register themselves with `command`, matching on a single
    # leading word of the (mention-stripped) message text.
    class Command
      class << self
        attr_accessor :command_classes

        def inherited(subclass)
          super
          Command.command_classes ||= []
          Command.command_classes << subclass
        end

        def command(name, &block)
          routes[name] = block
        end

        def routes
          @routes ||= {}
        end

        def invoke!(request)
          finalize_routes!

          routes.each_pair do |route, block|
            next unless request.matches?(route)

            result = call_command(request, block)
            return result if result
          end
          nil
        rescue TeamsStrava::Error => e
          e.message
        end

        private

        def call_command(request, block)
          if block
            block.call(request)
          elsif respond_to?(:call)
            send(:call, request)
          else
            raise NotImplementedError, name
          end
        end

        def finalize_routes!
          return if routes.any?

          command(command_name_from_class)
        end

        def command_name_from_class
          name ? name.split(':').last.downcase : object_id.to_s
        end
      end
    end
  end
end
