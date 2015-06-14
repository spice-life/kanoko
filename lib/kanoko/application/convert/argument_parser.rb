require 'kanoko/application/convert/function'

module Kanoko
  module Application
    class Convert
      class ArgumentParser
        include Enumerable
        extend Forwardable
        def_delegators :@args, :each, :to_a

        attr_reader :options

        def initialize(args)
          @args, @options = ArgumentParser.parse args
        end

        def to_path
          map { |i| "/#{i.join('/')}" }.join
        end
        alias path to_path

        private

        class << self
          def parse(path)
            args = []
            options = []
            items = path.split('/')
            while item = items.shift
              id = item.to_sym
              if Function.list.include?(id)
                function = Function.new
                method = function.method(id)
                arg = items.shift(method.arity)
                options.concat method.call(*arg)
                args.push [id, *arg]
              else
                break
              end
            end
            [args, options]
          end
        end
      end
    end
  end
end
