require 'uri'
require 'kanoko/configure'

module Kanoko
  # example:
  #   Kanoko.configure.kanoko_host = "http://example.com"
  #   p Kanoko.configure #=> #<Kanoko::Configure ...>
  def configure
    @configure ||= Configure.new
  end
  module_function :configure

  def configure=(value)
    @configure = value
  end

  def url_for(func, args, src)
    if configure.kanoko_host.nil?
      fail ConfigureError, "`kanoko_host' must be set"
    end
    "#{configure.kanoko_host}#{make_path(func, args, src)}"
  end
  module_function :url_for

  def make_hash(*args)
    configure.hash_proc.call(*args)
  end
  module_function :make_hash

  private

  def make_path(func, args, src)
    hash = make_hash(func, args, src)
    "/#{hash}/#{[func, args].map{|i| URI.encode_www_form_component(i)}.join('/')}/#{src}"
  end
  module_function :make_path
end
