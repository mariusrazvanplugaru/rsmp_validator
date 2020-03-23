require 'rsmp'
require_relative 'test_site'
require_relative 'test_supervisor'


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

include RSpec

def load_secrets path
	secrets_path = 'config/secrets.yaml'
	unless File.exist? secrets_path
		puts "Secrets file #{secrets_path} not found. Please add it and try again."
		exit
	end
	secrets = YAML.load_file(secrets_path)

	required_keys = ['security_codes']
	required_keys.each { |key| verify_presence_of_secret secrets, secrets_path, key }
	secrets
end

def verify_presence_of_secret secrets, secrets_path, key
	unless secrets[key]
		puts "The key '#{key}' is missing from #{secrets_path}. Please add it and try again."
		exit
	end
end


 def ask_user site, question, accept:''
	pointing = "\u{1f449}"
	print "#{pointing} " + question.colorize(:color => :light_magenta) + " "
	site.log "Asking user for input: #{question}", level: :test
	response = ASYNC_STDIN.gets.chomp
	if response == accept
		site.log "OK from user", level: :test
	else
		site.log "Test skipped by user", level: :test
		expect(response).to eq(accept), "Test skipped by user"
	end
 end


ASYNC_STDIN = Async::IO::Stream.new( Async::IO::Generic.new($stdin) )

VALIDATOR_CONFIG = YAML.load_file 'config/validator.yaml' rescue {}

rsmp_config_path = VALIDATOR_CONFIG['rsmp_config_path']
rsmp_config_path = 'config/ruby.yaml' unless rsmp_config_path
RSMP_CONFIG = YAML.load_file rsmp_config_path

LOG_CONFIG = YAML.load_file VALIDATOR_CONFIG['log_config_path'] rescue {}

SECRETS = load_secrets 'config/secrets.yaml'

#sugar
SUPERVISOR_CONFIG = RSMP_CONFIG['supervisor'] rescue {}
SITE_CONFIG = SUPERVISOR_CONFIG['sites'].values.first rescue {}
COMPONENT_CONFIG = SITE_CONFIG['components'] rescue {}
MAIN_COMPONENT = COMPONENT_CONFIG['main'].keys.first
STATUS_RESPONSE_TIMEOUT = SUPERVISOR_CONFIG['status_response_timeout']

puts "Using test config #{VALIDATOR_CONFIG['rsmp_config_path']}"

