require 'ruby-jwt'
require 'json'

keys = JSON.load File.new("keys.json")

token = ARGV[0]
sub = ARGV[1]

header = JSON.parse Base64.decode64(token.split(/\./).first)
key = OpenSSL::PKey::RSA.new(keys[header[:kid]]).public_key

decoded_token = JWT.decode ARGV[0], key, true, {
	:algorithm => 'RS256',
	:exp_leeway => 60,
	:verify_iss => true, :iss => 'https://securetoken.google.com/polymyr-162101',
	:verify_sub => true, :sub => sub, 
	:verify_iat => true, :iat_leeway => 60
	:verify_aud => true, :aud => ['polymyr-162101']
}

puts decoded_token