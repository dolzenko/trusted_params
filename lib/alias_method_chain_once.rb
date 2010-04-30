# *Correct* `alias_method_chain_once` implementation
class Module
  unless method_defined?(:alias_method_chain_once) ||
          private_method_defined?(:alias_method_chain_once)
    def alias_method_chain_once(target, feature)
      aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
      without_method = "#{aliased_target}_without_#{feature}#{punctuation}"

      # `method_defined?` matches public and protected methods,
      # also `*_method_defined?` family of methods is the portable
      # way to check for method existence, while `public_methods.include?`
      # will work either on 1.8 or 1.9 (depending on where symbol or string
      # is provided as method name)
      unless method_defined?(without_method) ||
              private_method_defined?(without_method)
        alias_method_chain(target, feature)
      end
    end
  end
end