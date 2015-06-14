ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'stringio'
require "rack/test"
require "exifr"
require "kanoko/application/convert"
