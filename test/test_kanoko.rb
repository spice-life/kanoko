require 'helper'

class TestKanoko < Minitest::Test
  def setup
    Kanoko.configure.digest_func = "sha1"
    Kanoko.configure.secret_key = "test"
  end

  def change_hash_proc(hash_proc)
    before = Kanoko.configure.hash_proc
    Kanoko.configure.hash_proc = hash_proc
    yield
    Kanoko.configure.hash_proc = before
  end

  def test_configure
    assert_kind_of Kanoko::Configure, Kanoko.configure
  end

  def test_configure_with_block
    assert_equal "sha1", Kanoko.configure.digest_func
    Kanoko.configure.digest_func = "ok"
    assert_equal "ok", Kanoko.configure.digest_func
  end

  def test_path_for_with_default_hash_proc
    change_hash_proc(proc{ "aaa" }) do
      path = Kanoko.path_for(:test_func, "test_args", "test_path")
      assert_equal "/aaa/test_func/test_args/test_path", path

      path = Kanoko.path_for(:test_func, "/?-_=!@#<>\\", "/?-_=!@#<>\\")
      assert_equal "/aaa/test_func/%2F%3F-_%3D%21%40%23%3C%3E%5C//?-_=!@#<>\\", path

      path = Kanoko.path_for(:test_func, "test_args", :test_func2, "test_args2", "test_path")
      assert_equal "/aaa/test_func/test_args/test_func2/test_args2/test_path", path
    end
  end

  def test_make_hash
    change_hash_proc(proc{ "bbb" }) do
      assert_equal "bbb", Kanoko.make_hash(:test_func, "test_args", "test_path")
    end
  end

  def test_make_hash_custom_hash_proc
    change_hash_proc(proc{ "ccc" }) do
      assert_equal "ccc", Kanoko.make_hash(:test_func, "test_args", "test_path")
    end
  end
end
