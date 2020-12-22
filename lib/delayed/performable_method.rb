module Delayed
  class PerformableMethod
    attr_accessor :object, :method_name, :args

    def initialize(object, method_name, args)
      raise NoMethodError, "undefined method `#{method_name}' for #{object.inspect}" unless object.respond_to?(method_name, true)

      if object.respond_to?(:persisted?) && !object.persisted?
        raise(ArgumentError, "job cannot be created for non-persisted record: #{object.inspect}")
      end

      self.object       = object
      self.args         = args
      self.method_name  = method_name.to_sym
    end

    def display_name
      if object.is_a?(Class)
        "#{object}.#{method_name}"
      else
        "#{object.class}##{method_name}"
      end
    end

    if RUBY_VERSION >= '3.0'
      def perform
        if args_is_a_hash?
          object.send(method_name, **args.first)
        else
          object.send(method_name, *args)
        end if object
#      rescue => e
#        p e.message
#        p args
#        raise e
      end

      def args_is_a_hash?
        args.size == 1 && args.first.is_a?(Hash)
      end
    else
      def perform
        object.send(method_name, *args) if object
      end
    end

    def method(sym)
      object.method(sym)
    end

    # rubocop:disable MethodMissing
    if RUBY_VERSION >= '3.0'
      def method_missing(symbol, ...)
        object.send(symbol, ...)
      end
    else
      def method_missing(symbol, *args)
        object.send(symbol, *args)
      end
    end
    # rubocop:enable MethodMissing

    def respond_to?(symbol, include_private = false)
      super || object.respond_to?(symbol, include_private)
    end
  end
end
