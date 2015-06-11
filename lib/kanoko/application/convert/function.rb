module Kanoko
  module Application
    class Convert
      class Function
        include Enumerable
        extend Forwardable
        def_delegators :@args, :each, :to_a, :to_h

        def initialize(args)
          @args = parse args
        end

        def to_path
          paths = []
          @args.each do |func, arg|
            paths << "/#{func}/#{arg}"
          end
          paths.join
        end

        private

        def parse(args)
          hash = {}
          items = args.split('/')
          items.each_slice(2) do |funcname, arg|
            if funcname.match(/\./)
              break
            else
              hash[funcname.to_sym] = arg.to_s
            end
          end
          hash
        end
      end
    end
  end
end
