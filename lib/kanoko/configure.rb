require 'base64'
require 'openssl'
require 'kanoko/errors'

module Kanoko
  class Configure
    attr_accessor :digest_func, :secret_key, :hash_proc

    # digest_func expect String
    # secret_key expect String
    # hash_proc expect Proc
    #
    # example:
    #   Kanoko.configure do |c|
    #     c.digest_func = "sha1"
    #     c.secret_key = "secret"
    #   end
    #   Kanoko.path_for(:resize, "100x100") #=> "/hashing_value/resize/100x100"
    def initialize
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
  end
end
