require 'minitest/autorun'
require 'kanoko/configure'

class TestKanokoConfigure < Minitest::Test
  def setup
    @config = Kanoko::Configure.new
  end

  def test_resource_host
    assert_raises(Kanoko::ConfigureError) { @config.resource_host = "/example.com" }

    @config.resource_host = "example.com"
    assert_equal "http://example.com", @config.resource_host

    @config.resource_host = "http://example.com"
    assert_equal "http://example.com", @config.resource_host

    @config.resource_host = "https://example.com"
    assert_equal "https://example.com", @config.resource_host
  end

  def test_hash_proc_by_default_error
    @config.digest_func = nil
    @config.secret_key = nil
    assert_raises(Kanoko::ConfigureError){ @config.hash_proc.call }

    @config.digest_func = "sha1"
    @config.secret_key = nil
    assert_raises(Kanoko::ConfigureError){ @config.hash_proc.call }

    @config.digest_func = nil
    @config.secret_key = "test"
    assert_raises(Kanoko::ConfigureError){ @config.hash_proc.call }
  end

  def test_hash_proc_by_default
    @config.digest_func = "sha1"
    @config.secret_key = "test"
    assert_equal "yrYrwA2D_XJwEyaWOr3S8GPWtd8=", @config.hash_proc.call("aaa")
  end
end
