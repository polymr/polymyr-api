require 'ruby-jwt'
require 'json'

keys = JSON.load File.new("keys.json")

token = ARGV[0]
header = JSON.parse token.split(/\./).first

key = OpenSSL::PKey::RSA.new(keys[header.kid]).public_key

begin
  	decoded_token = JWT.decode ARGV[0], key, true, {
		:algorithm => 'RS256',
		:exp_leeway => 60,
		:aud => ['polymyr-162101'],
		:verify_aud => true,
		:verify_iat => true,
		:verify_sub => true,
	}

rescue JWT::InvalidIatError
rescue JWT::ImmatureSignature
rescue JWT::ExpiredSignature
	  # Handle expired token, e.g. logout user or deny access
end

puts decoded_token