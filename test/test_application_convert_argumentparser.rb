require 'helper'

class TestKanokoApplicationConvertArgumentParser < Minitest::Test
  include Kanoko::Application
  class Kanoko::Application::Convert::Function
    def empty_option
      []
    end
    def one_option
      ['func1']
    end
    def one_arg_and_one_option(arg)
      ['func2', arg]
    end
  end

  def test_empty
    a = Convert::ArgumentParser.new("")
    assert_equal [], a.to_a
    assert_equal [], a.options
    assert_equal "", a.path
  end

  def test_empty_option
    a = Convert::ArgumentParser.new("empty_option/10x10")
    assert_equal [[:empty_option]], a.to_a
    assert_equal [], a.options
    assert_equal "/empty_option", a.path
  end

  def test_one_option
    a = Convert::ArgumentParser.new("one_option/10x10")
    assert_equal [[:one_option]], a.to_a
    assert_equal "/one_option", a.path
    assert_equal ['func1'], a.options
  end

  def test_one_arg_and_one_option
    a = Convert::ArgumentParser.new("one_arg_and_one_option/10x10")
    assert_equal [[:one_arg_and_one_option, '10x10']], a.to_a
    assert_equal "/one_arg_and_one_option/10x10", a.path
    assert_equal ['func2', '10x10'], a.options
  end

  def test_one_option_and_one_arg_and_one_option
    a = Convert::ArgumentParser.new("one_option/one_arg_and_one_option/10x10")
    assert_equal [[:one_option], [:one_arg_and_one_option, '10x10']], a.to_a
    assert_equal "/one_option/one_arg_and_one_option/10x10", a.path
    assert_equal ['func1', 'func2', '10x10'], a.options
  end

  def test_nothing
    a = Convert::ArgumentParser.new("nothing/10x10")
    assert_equal [], a.to_a
    assert_equal "", a.path
    assert_equal [], a.options
  end
end
