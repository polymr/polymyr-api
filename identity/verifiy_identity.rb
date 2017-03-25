require 'jwt'
require 'json'
require 'net/http'

token = ARGV[0]
sub = ARGV[1]
dir = ARGV[2]

keys = JSON.load File.new("#{dir}identity/keys.json")

header = JSON.parse Base64.decode64(token.split(/\./).first)

unless keys.key?(header['kid'])
	newKeys = Net::HTTP.get(URI('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'))
	newJsonKeys = JSON.parse newKeys
	keys = newJsonKeys
	File.write('#{dir}identity/keys.json', newKeys)
end

key = OpenSSL::X509::Certificate.new(keys[header['kid']]).public_key

begin
	decoded_token = JWT.decode token, key, true, {
		:algorithm => 'RS256',
		:exp_leeway => 60,
		:verify_iss => true, :iss => 'https://securetoken.google.com/polymyr-a5014',
		# :verify_sub => true, :sub => sub, 
		:verify_iat => true, :iat_leeway => 60,
		:verify_aud => true, :aud => 'polymyr-a5014'
	}
rescue => error
	puts error.message
	exit
end

puts "success"