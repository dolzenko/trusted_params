# ## TrustedParams
#
# Trust only the params you indeed created inputs for (half-assed solution to the mass assignment problem)
class TrustedParams
  include ::ActionView::Helpers::TagHelper

  InFormTagKey = :__trusted_params_in_form_tag_key__

  cattr_accessor :trusted_params_token_name
  self.trusted_params_token_name = "trusted_params_token"

  attr_accessor :invoked_from
  
  def initialize(invoked_from)
    @trusted_params = []
    self.invoked_from = invoked_from
  end

  def register_trusted_param(name)
    @trusted_params << name 
  end
  
  def token_tag
    tag_html = tag(:input, :type => "hidden", :name => self.class.trusted_params_token_name, :value => encrypted_trusted_params_list)
    content_tag(:div, tag_html, :style => 'margin:0;padding:0;display:inline')
  end

  def self.encryptor
    ActiveSupport::MessageEncryptor.new(Rails.application.config.secret_token)
  end

  def encrypted_trusted_params_list
    params = @trusted_params.map { |e| e.to_s }

    self.class.encryptor.encrypt_and_sign(Marshal.dump(params))
  end

  def self.trusted_params(params)
    if (params_token = params[trusted_params_token_name]).blank?
#      raise ArgumentError, "Can't determine trusted params, " \
#                           "`#{ trusted_params_token_name }' parameter is missing"
      return {}
    end
    
    trusted_list = Marshal.load(encryptor.decrypt_and_verify(params_token))
    sample_trusted_params = Rack::Utils.parse_nested_query(trusted_list.map { |k| "#{ k }=1" }.join("&")) 

    remove_untrusted_nested_params(params, sample_trusted_params)
  end

  def self.remove_untrusted_nested_params(params, sample_trusted_params)
    trusted_params = params.slice(*sample_trusted_params.keys)
    trusted_params.each do |param_name, param_value|
      if param_value.is_a?(Hash)
        trusted_param_value = remove_untrusted_nested_params(param_value, sample_trusted_params[param_name])
        param_value.replace(trusted_param_value)
      end
    end
    trusted_params
  end

  def self.inject_trusted_params(params)
    trusted = trusted_params(params)
    inject_trusted_params_helper(params, trusted)
  end

  def self.inject_trusted_params_helper(params, trusted)
    params.define_singleton_method(:trusted) do |*default_trusted_params|
      trusted[k].merge(v.slice(*default_trusted_params))
    end

    params.each do |k, v|
      if v.is_a?(Hash)
        v.define_singleton_method(:trusted) do |*default_trusted_params|
          trusted[k].merge(v.slice(*default_trusted_params))
        end
      end
    end
  end
end