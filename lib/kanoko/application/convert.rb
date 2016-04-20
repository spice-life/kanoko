require 'sinatra'
require 'net/http'
require 'tempfile'
require 'kanoko'
require 'mime/types'

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
      require 'kanoko/application/convert/function'

      IMAGE_TYPES = MIME::Types.select do |m|
        m.media_type == 'image'
      end
      TYPE_MAP = IMAGE_TYPES.map { |i|
        [i.to_s, i.preferred_extension]
      }.to_h
      EXT_MAP = IMAGE_TYPES.each_with_object({}) do |i, h|
        i.extensions.each do |ext|
          h[ext] = i.to_s
        end
      end
      QUERY_REGEXP = /\?.*/

      # /123abc456def=/resize/200x200/crop/100x100/path/to/src
      get '/:hash/*' do
        # REQUEST_URI dependent on unicorn.
        # request.path should be use only testing
        raw_request_uri = if env["REQUEST_URI"]
                            env["REQUEST_URI"]
                          else
                            "#{request.path}#{request.params.empty? ? "" : "?#{request.query_string}"}"
                          end
        request_params = raw_request_uri.split('/').tap(&:shift)
        hash = request_params.shift
        unless 0 < request_params.length
          logger.error "invalid url #{request_uri}"
          return 400
        end

        list = Kanoko::Application::Convert::Function.list
        convert_options = []
        arguments = []
        to_ext = File.extname(request_params.last).sub(QUERY_REGEXP, '')[1..-1]
        while id = request_params.shift.to_sym
          if id == :to
            to_ext = request_params.shift
            arguments << id << to_ext
          elsif list.include?(id)
            arguments << id
            method = Function.new.method(id)
            arg = request_params.shift(method.arity)
            arg.map! { |i| URI.decode_www_form_component i }
            arguments.concat arg if 0 < arg.length
            convert_options.concat method.call(*arg)
          else
            request_params.unshift(id.to_s)
            break
          end
        end

        check_path = request_params.map { |i| URI.decode_www_form_component(i) }.join('/')
        unless hash == Kanoko.make_hash(*arguments, check_path)
          logger.error "hash check failed #{[*arguments, check_path]}"
          return 400
        end

        src_path = request_params.join('/')
        res = http_get(URI.parse("#{(request.secure? ? 'https' : 'http')}://#{src_path}"))
        if res.nil?
          return 404
        end
        after_response res

        Tempfile.create("src") do |src_file|
          src_file.write res.body
          src_file.fdatasync

          t = TYPE_MAP[res.content_type]
          src_type = if t
            "#{t}:"
          else
            ""
          end

          dst_name = if to_ext.nil?
            "dst"
          else
            ["dst", ".#{to_ext}"]
          end

          Tempfile.create(dst_name) do |dst_file|
            system_command = [
              { "OMP_NUM_THREADS" => "1" },
              'convert',
              '-depth', '8',
              convert_options,
              "#{src_type}#{src_file.path}",
              dst_file.path,
            ].flatten
            result = system *system_command

            unless result
              logger.error "command fail $?=#{$CHILD_STATUS.inspect}"
              return 500
            end

            content_type EXT_MAP[to_ext]
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

      error 404 do
        ""
      end
    end
  end
end
