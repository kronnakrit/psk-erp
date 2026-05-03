# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, :https, :blob
    policy.object_src  :none
    # chart.js and tom-select and jsbarcode are loaded from CDNs
    policy.script_src  :self, "https://cdn.jsdelivr.net", "https://unpkg.com"
    # Tailwind utility classes generate inline styles; unsafe-inline needed here
    policy.style_src   :self, :unsafe_inline, "https://cdn.jsdelivr.net"
    policy.connect_src :self
    policy.frame_src   :none
  end

  # Generate a unique nonce per request for inline scripts
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Automatically adds nonce to javascript_tag, javascript_include_tag,
  # javascript_importmap_tags, and stylesheet_link_tag helpers.
  config.content_security_policy_nonce_auto = true
end
