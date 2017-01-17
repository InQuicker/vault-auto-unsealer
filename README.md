# vault-auto-unsealer

**vault-auto-unsealer** is an application to assist in running [Vault](https://www.vaultproject.io/) in a [Kubernetes](http://kubernetes.io/) cluster.
It runs a control loop that will unseal Vault if necessary, so that human intervention is not needed to unseal Vault if/when Vault's pod is restarted by Kubernetes.
Of course, this means that the value of Vault's unseal process is foregone, but this may be an acceptable compromise when running in an environment where the unseal key is protected via some other means, and the ability to keep Vault running without human intervention when it restarts is critical.

## Configuration

Required environment variables:

* `VAULT_ADDR`: The address of the Vault server to operate on. Example: http://127.0.0.1:8200
* `PGP_KEY_PATH`: Path to a file containing the OpenPGP public key that should be used to encrypt the unseal key and initial root token.
  This file should be the Base64 encoding of the binary version of the public key, NOT the ASCII armored format.
  Make sure you don't accidentally append a newline at the end of the file!
* `UNSEAL_KEY`: The raw decrypted unseal key.
  When first deployed, set this to a blank string and vault-auto-unsealer will initialize Vault.

## Usage

When first deployed, set the environment variable `UNSEAL_KEY` to an empty string.
vault-auto-unsealer will initialize Vault, configured for a single unseal key.
It will then print the unseal key and initial root token, encrypted with the supplied OpenPGP public key, to standard output.

Decrypt the unseal key:

``` bash
echo -n "$UNSEAL_KEY" | base64 -D | gpg2 --decrypt
```

The initial root token is decrypted in the same manner.

Then redeploy vault-auto-unsealer with the environment variable `UNSEAL_KEY` set to the decrypted unseal key.
From this point on, vault-auto-unsealer will run in a loop, unsealing the Vault whenever it finds it sealed.

## Legal

vault-auto-unsealer is released under the MIT license.
See `LICENSE` for details.
