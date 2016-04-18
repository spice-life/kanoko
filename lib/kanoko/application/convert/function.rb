module Kanoko
  module Application
    class Convert
      # You can make customize function.
      # It just make or overwhrite instance method.
      # example:
      #   class Kanoko::Application::Convert::Function
      #     # get "/new_func/new_value"
      #     # => add imagemagick option
      #     # -new-option new_value
      #     def new_func(arg)
      #       ['-new-option', arg]
      #     end
      #   end
      class Function
        class << self
          def list
            instance_methods(false)
          end
        end

        def crop(arg)
          [
            '-crop', arg
          ]
        end

        def fill(arg)
          [
            '-gravity', 'north',
            '-extent', arg,
            '-background', 'transparent',
          ]
        end

        def resize(arg)
          [
            '-define', "jpeg:size=#{arg}",
            '-thumbnail', arg,
          ]
        end

        def auto_orient
          [
            '-auto-orient'
          ]
        end

        def strip
          [
            '-strip',
          ]
        end
      end
    end
  end
end
