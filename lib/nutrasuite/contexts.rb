module Nutrasuite
  module ContextHelpers
    def a(name, &block)
      name = "a " << name
      Context.push(name, &block)
    end

    def an(name, &block)
      name = "an " << name
      Context.push(name, &block)
    end

    def and(name, &block)
      name = "and " << name
      Context.push(name, &block)
    end

    def that(name, &block)
      name = "that " << name
      Context.push(name, &block)
    end

    # Code to be run before the context
    def setup(&block)
      if Context.current_context?
        Context.current_context.setups << block
      else
        warn "Not in a context"
      end
    end

    # Code to be run when the context is finished
    def teardown(&block)
      if Context.current_context?
        Context.current_context.teardowns << block
      else
        warn "Not in a context"
      end
    end

    # Defines an actual test based on the given context
    def it(name, &block)
      build_test(name, &block)
    end

    def build_test(name, &block)
      test_name = Context.build_test_name(name)

      setups = []
      teardowns = []
      Context.context_stack.each do |context|
        setups.concat(context.setups)
        teardowns.concat(context.teardowns)
      end

      define_method test_name do
        setups.each { |setup| setup.call }
        block.call
        teardowns.each { |teardown| teardown.call }
      end
    end

    def warn(message)
      puts " * Warning: #{message}"
    end

    include MiniTest::Assertions
  end

  class Context
    include ContextHelpers

    attr_reader :name, :setups, :teardowns

    def initialize(name, &block)
      @name = name
      @block = block

      @setups = []
      @teardowns = []
    end

    def build
      @block.call
    end

    def self.build_test_name(name="")
      full_name = "test "
      @context_stack.each do |context|
        full_name << context.name << " "
      end
      full_name << name
    end

    def self.push(name, &block)
      @context_stack ||= []

      context = Context.new(name, &block)
      @context_stack.push(context)

      context.build

      @context_stack.pop
    end

    def self.context_stack
      @context_stack
    end

    def self.current_context
      @context_stack.last
    end

    def self.current_context?
      !@context_stack.empty?
    end
  end
end

class MiniTest::Unit::TestCase
  extend Nutrasuite::ContextHelpers
end
