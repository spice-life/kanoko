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
      get '/:hash/:func/:args/*' do
        hash = params[:hash]
        func = params[:func]
        args = params[:args]
        src_path = env["REQUEST_URI"].sub(%r{/.*?/.*?/.*?/(.*)}, '\1')

        unless hash == Kanoko.make_hash(func, args, src_path)
          logger.error "hash check failed #{[func, args, src_path]}"
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
            result = case func.to_sym

            when :crop
              system(default_env,
                'convert',
                '-thumbnail', "#{args}^",
                '-gravity', 'north',
                '-extent', args,
                '-background', 'transparent',
                '-depth', '8',
                src_file.path, dst_file.path)

            when :resize
              system(default_env,
                'convert',
                '-thumbnail', args,
                '-depth', '8',
                src_file.path, dst_file.path)

            else
              logger.error "undefined func #{func}"
              return 400
            end

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
          headers[key] ||= value
        end
      end
    end
  end
end
