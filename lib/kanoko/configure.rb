require 'base64'
require 'openssl'
require 'kanoko/errors'

module Kanoko
  class Configure
    attr_accessor :digest_func, :secret_key, :hash_proc

    # resource_host expect String
    # digest_func expect String
    # secret_key expect String
    # hash_proc expect Proc
    #
    # example:
    #   Kanoko.configure.tap do |c|
    #     c.resource_host = "http://example.com"
    #     c.digest_func = "sha1"
    #     c.secret_key = "secret"
    #   end
    #   Kanoko.url_for(:resize, "100x100") #=> "http://example.com/.../.../..."
    def initialize
      @resource_host = nil
      @digest_func = nil
      @secret_key = nil
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

    def resource_host=(host)
      @resource_host = normalize_url(host)
    end

    def resource_host
      @resource_host
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
        fail ConfigureError, "invalid resource_host `#{host}'"
      end
    end
  end
end
