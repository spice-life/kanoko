require 'uri'
require 'kanoko/configure'
require 'kanoko/errors'
require 'kanoko/version'

module Kanoko
  # example:
  #   Kanoko.configure.digest_func = "sha1"
  #   p Kanoko.configure #=> #<Kanoko::Configure ...>
  def configure
    @configure ||= Configure.new
    if block_given?
      yield @configure
    else
      @configure
    end
  end
  module_function :configure

  def configure=(value)
    @configure = value
  end
  module_function :configure=

  def path_for(*function, src)
    hash = make_hash(*function, src)
    "/#{hash}/#{function.map { |i| URI.encode_www_form_component(i) }.join('/')}/#{src}"
  end
  module_function :path_for

  def make_hash(*args)
    configure.hash_proc.call(*args)
  end
  module_function :make_hash
end
