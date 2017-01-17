# frozen_string_literal: true

Signal.trap("TERM") do
  exit
end

if ENV["VAULT_ADDR"].nil?
  abort "Environment variable VAULT_ADDR must be set to the address of the Vault server, e.g. http://127.0.0.1:8200"
end

require "vault"

unless Vault.sys.init_status.initialized?
  puts "Attempting to initialize the Vault server."

  pgp_key_path = ENV["PGP_KEY_PATH"]

  if pgp_key_path.nil?
    abort "Environment variable PGP_KEY_PATH must be set to the path of a file containing a Base64-encoded (but not ASCII armored) OpenPGP public key that Vault's keys should be encrypted with."
  end

  pgp_key = File.read(pgp_key_path).chomp

  response = Vault.sys.init(
    pgp_keys: [pgp_key],
    root_token_pgp_key: pgp_key,
    secret_shares: 1,
    secret_threshold: 1,
  )

  puts <<EOS
Vault initialized successfully.
The following values are Base64 encoded and encrypted with OpenPGP.

Unseal key: #{response.keys_base64.first}
Root token: #{response.root_token}

Redeploy vault-auto-unsealer with the environment variable UNSEAL_KEY to the decrypted unseal key.
vault-auto-unsealer will now sleep until terminated with SIGTERM, so that Kubernetes will not try to restart it before an operator can redeploy it with UNSEAL_KEY set.
EOS

  sleep
end

unseal_key = ENV["UNSEAL_KEY"]

if unseal_key.nil? || unseal_key == ""
  abort "Environment variable UNSEAL_KEY must be set to the decrypted Vault unseal key."
end

loop do
  if Vault.sys.seal_status.sealed?
    Vault.sys.unseal(unseal_key)

    puts "Vault has been unsealed."
  end

  sleep 30
end