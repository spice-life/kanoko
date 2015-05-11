require 'base64'
require 'openssl'
require 'kanoko/errors'

module Kanoko
  class Configure
    attr_accessor :digest_func, :secret_key, :hash_proc

    # kanoko_host expect String
    # digest_func expect String
    # secret_key expect String
    # hash_proc expect Proc
    #
    # example:
    #   Kanoko.configure do |c|
    #     c.kanoko_host = "http://example.com"
    #     c.digest_func = "sha1"
    #     c.secret_key = "secret"
    #   end
    #   Kanoko.url_for(:resize, "100x100") #=> "http://example.com/.../.../..."
    def initialize
      @kanoko_host = nil
      @digest_func = ENV['KANOKO_DIGEST_FUNC']
      @secret_key = ENV['KANOKO_SECRET_KEY']
      @hash_proc = ->(*args){
        if @digest_func.nil? || @secret_key.nil?
          fail ConfigureError, "`digest_func' and `secret_key' must be set"
        end
        Base64.urlsafe_encode64(
          OpenSSL::HMAC.digest @digest_func,
          @secret_key,
          args.map(&:to_s).join(',')
        )
      }
    end

    # for make url to kanoko application
    # example:
    #   kanoko_host = "http://example.com"
    #   p kanoko_host #=> "http://example.com"
    #   kanoko_host = "example.com"
    #   p kanoko_host #=> "http://example.com"
    #   kanoko_host = "//example.com"
    #   p kanoko_host #=> "http://example.com"
    def kanoko_host=(host)
      @kanoko_host = normalize_url(host)
    end

    def kanoko_host
      @kanoko_host
    end

    private

    def normalize_url(host)
      case host
      when %r{\Ahttps?://}
        host
      when %r{\A[^/]}
        "http://#{host}"
      when %r{\A//}
        "http:#{host}"
      else
        fail ConfigureError, "invalid kanoko_host `#{host}'"
      end
    end
  end
end
