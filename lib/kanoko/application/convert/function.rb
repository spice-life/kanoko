module Kanoko
  module Application
    class Convert
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
      end
    end
  end
end
