require 'sinatra'
require 'net/http'
require 'tempfile'
require 'kanoko'

# This is an experimental implementation.
# You can set configure and other.
# This application receve url make by Kanoko.url_for().
# You can choice function that image processing.
# Image resource can get by url,
# And that write once to file,
# And image processing by imagemagick,
# And that read file binary.
#
# example:
#   require 'kanoko/application/convert'
#
#   ENV['KANOKO_DIGEST_FUNC'] = "sha1"
#   ENV['KANOKO_SECRET_KEY'] = "secret"
#
#   class MyApp < Kanoko::Application::Convert
#     before do
#       content_type 'image/png'
#     end
#     configure :production do
#       require 'newrelic_rpm'
#     end
#   end
#
#   run MyApp
module Kanoko
  module Application
    class Convert < Sinatra::Application
      # /123abc456def=/resize/200x200/crop/100x100/path/to/src
      get '/:hash/*' do
        request_uri = URI.parse env["REQUEST_URI"]
        hash = params[:hash]
        unless params[:splat]
          logger.error "invalid url #{request_uri}"
          return 400
        end
        splat = params[:splat][0]
        function = Function.new splat
        hint_src = splat[function.to_path.length..-1]
        hint_index = request_uri.to_s.index(hint_src)
        src_path = request_uri.to_s[hint_index..-1]

        unless hash == Kanoko.make_hash(*(function.to_a.flatten), src_path)
          logger.error "hash check failed #{[*(function.to_a.flatten), src_path]}"
          return 400
        end

        res = http_get(URI.parse("#{(request.secure? ? 'https' : 'http')}://#{src_path}"))
        if res.nil?
          return 404
        end
        after_response res

        Tempfile.open("src") do |src_file|
          src_file.write res.body
          src_file.fdatasync

          Tempfile.open("dst") do |dst_file|
            default_env = {"OMP_NUM_THREADS" => "1"}
            command = 'convert'
            default_options = [
              '-depth', '8'
            ]
            options = []

            function.each do |name, arg|
              func_options = case name.to_sym
                when :crop
                  [
                    '-crop', arg
                  ]

                when :fill
                  [
                    '-gravity', 'north',
                    '-extent', arg,
                    '-background', 'transparent',
                  ]

                when :resize
                  [
                    '-define', "jpeg:size=#{arg}",
                    '-thumbnail', arg,
                  ]

                else
                  logger.error "undefined func #{name}"
                  return 400
                end

              options.concat func_options
            end

            system_command = [
              default_env,
              command,
              default_options,
              options,
              src_file.path,
              dst_file.path
            ].flatten

            result = system *system_command

            unless result
              logger.error "command fail $?=#{$?.inspect}"
              return 500
            end

            dst_file.read
          end
        end
      end

      private

      def http_get(uri)
        retries = 2
        req = Net::HTTP::Get.new(uri.request_uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 1
        http.use_ssl = true if uri.scheme == 'https'
        begin
          res = http.start do |http|
            http.request(req)
          end
          res.value
          res
        rescue => e
          if 1 < retries
            retries -= 1
            sleep rand(0..0.3)
            retry
          end
          logger.error "Can not get image from '#{uri}' with #{e.message}"
          nil
        end
      end

      def after_response(res)
        res.each do |key, value|
          case key.downcase
          when "status"
            next
          else
            headers[key] ||= value
          end
        end
      end
    end
  end
end

require 'kanoko/application/convert/function'
