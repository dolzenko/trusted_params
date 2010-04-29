require File.expand_path("../alias_method_chain_once", __FILE__)

module ActionView
  module Helpers
    module TagHelper
      # `tag` is called by all helpers, when Thread.current[TrustedParams::InFormTagKey]
      # any encountered input tag with present name is added to the trusted params
      def tag_with_trusted_params(*args)
        if trusted_params = Thread.current[TrustedParams::InFormTagKey]
          tag_name = args[0]
          options = args[1]
          if tag_name.to_s == "input" &&
                  options.is_a?(Hash) &&
                  (input_name = options["name"] || options[:name])
            trusted_params.register_trusted_param(input_name)
          end
        end
        tag_without_trusted_params(*args)
      end

      alias_method_chain_once :tag, :trusted_params
    end

    module FormTagHelper
      # `extra_tags_for_form` is called when `form_tag` with block finished,
      # usually to add authenticity_token to POST forms
      def extra_tags_for_form_with_trusted_params(*args)
        default = extra_tags_for_form_without_trusted_params(*args)
        if (trusted_params = Thread.current[TrustedParams::InFormTagKey]) &&
                trusted_params.invoked_from == :form_tag
          default << trusted_params.token_tag
        end
        default
      end

      alias_method_chain_once :extra_tags_for_form, :trusted_params

      # `form_tag`, also called by `form_for`
      def form_tag_with_trusted_params(*args, &block)
        # no way for us to track inputs added to the form when `form_tag` is
        # used just to generate opening tag
        return form_tag_without_trusted_params(*args, &block) unless block

        begin
          # if block passed - record all names for all inputs generated
          # while `form_tag` is running
          Thread.current[TrustedParams::InFormTagKey] = TrustedParams.new(:form_tag)

          form_tag_without_trusted_params(*args, &block)
        ensure
          Thread.current[TrustedParams::InFormTagKey] = nil
        end
      end

      alias_method_chain_once :form_tag, :trusted_params
    end

    module FormHelper
      def form_for_with_trusted_params(*args, &block)
        Thread.current[TrustedParams::InFormTagKey] = TrustedParams.new(:form_for)
        # pass new block to original `form_for` which writes trusted_params_token
        # at the end
        new_block = Proc.new do |*args|
          output = block.call(*args)
          if (trusted_params = Thread.current[TrustedParams::InFormTagKey]) &&
                trusted_params.invoked_from == :form_for
            output.safe_concat(trusted_params.token_tag)
          end
          output
        end
        form_for_without_trusted_params(*args, &new_block)
      ensure
        Thread.current[TrustedParams::InFormTagKey] = nil
      end

      alias_method_chain_once :form_for, :trusted_params
    end
  end
end

module ActiveSupport
  class HashWithIndifferentAccess < Hash
    def trusted(*default_trusted_params)
      TrustedParams.trusted(self, *default_trusted_params)
    end
  end
end
