require 'net/http'
require 'set'

describe "Choria Prometheus Metrics" do
  let(:expected_metrics) do
    data = Set[
      "choria_machine_nagios_start_time",
      "choria_machine_nagios_watcher_checks_count",
      "choria_machine_nagios_watcher_last_run_seconds",
      "choria_machine_nagios_watcher_status"
    ]
  end

  it "connects to http://puppet.choria:9100/metrics and validates metrics" do
    uri = URI('http://localhost:9100/metrics')

    begin
      response = Net::HTTP.get_response(uri)
    rescue StandardError => e
      fail "Failed to connect to the metrics endpoint: #{e.message}"
    end

    expect(response.code).to eq('200'), "Expected HTTP 200 but got #{response.code}"
    expect(response.body).to_not be_empty

    actual_metrics = response.body.each_line
                             .map(&:strip)
                             .select { |line| line.start_with?('choria_') }
                             .map { |line| line.split(/[{ ]/).first }
                             .to_set


    expected_metrics.each do |metric_name|
      expect(actual_metrics).to include(metric_name), "Documented metric '#{metric_name}' was not found in the live metrics output"
    end
  end
end
