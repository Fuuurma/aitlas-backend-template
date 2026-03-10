defmodule Aitlas.Crypto do
  @moduledoc """
  AES-256-GCM encryption for BYOK (Bring Your Own Key) API keys.

  Provides secure encryption/decryption for storing user API keys.
  Uses AES-256-GCM with a 12-byte IV for authenticated encryption.

  ## Security Notes

  - NEVER assign `decrypt/2` result to a variable for logging
  - ALWAYS use decrypted values inline and discard immediately
  - The encryption key is loaded from `ENCRYPTION_KEY` env var
  """

  @aad "aitlas-api-key-v1"

  @doc """
  Encrypt an API key with AES-256-GCM.
  Returns {ciphertext_base64, iv_base64}.

  ## Example

      {encrypted, iv} = Crypto.encrypt("sk-xxx")

  IMPORTANT: Never assign the result to a named variable in logs.
  Always use inline in DB insert.
  """
  def encrypt(plaintext) when is_binary(plaintext) do
    key = get_key()
    iv = :crypto.strong_rand_bytes(12)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, @aad, true)

    encrypted = Base.encode64(ciphertext <> tag)
    iv_b64 = Base.encode64(iv)

    {encrypted, iv_b64}
  end

  @doc """
  Decrypt an API key.
  Returns the plaintext string.

  IMPORTANT: Never log the return value. Use immediately and discard.
  """
  def decrypt(encrypted_b64, iv_b64) when is_binary(encrypted_b64) and is_binary(iv_b64) do
    key = get_key()
    iv = Base.decode64!(iv_b64)

    combined = Base.decode64!(encrypted_b64)
    ciphertext_len = byte_size(combined) - 16
    <<ciphertext::binary-size(ciphertext_len), tag::binary-size(16)>> = combined

    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, @aad, tag, false)
  end

  defp get_key do
    :aitlas
    |> Application.get_env(:encryption_key)
    |> Base.decode16!(case: :mixed)
  end
end
