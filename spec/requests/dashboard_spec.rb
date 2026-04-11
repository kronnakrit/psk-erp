require "rails_helper"

RSpec.describe "Root route smoke test", type: :request do
  it "renders the root path with HTTP 200 quickly" do
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    get root_path
    elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000

    expect(response).to have_http_status(:ok)
    expect(elapsed_ms).to be < 200
  end
end
