# frozen_string_literal: true

# Rack::Attack — rate limiting and throttling
# https://github.com/rack/rack-attack

class Rack::Attack
  # Throttle login attempts by IP (10 per minute)
  throttle("logins/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # Throttle login attempts by username (5 per minute) to slow credential stuffing
  throttle("logins/username", limit: 5, period: 1.minute) do |req|
    if req.path == "/login" && req.post?
      req.params["user"]&.dig("username").to_s.downcase.presence
    end
  end

  # Throttle general API calls by IP (300 per minute)
  throttle("api/ip", limit: 300, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Return a 429 with JSON body for throttled API requests
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    headers = {
      "Content-Type"   => "application/json",
      "Retry-After"    => match_data[:period].to_s
    }
    [429, headers, [{ error: "Rate limit exceeded. Please try again later." }.to_json]]
  end
end
