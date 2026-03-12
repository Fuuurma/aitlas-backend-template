defmodule FImprove.Crypto do
  @moduledoc """
  AES-256-GCM encryption for sensitive data.
  """
  
  @aad "FImprove.APIKey"
  
  @doc """
  Encrypt a plain text string.
  
  Returns base64-encoded ciphertext.
  """
  def encrypt(plaintext) do
    key = get_encryption_key()
    iv = :crypto.strong_rand_bytes(12)
    
    {ciphertext, tag} = :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      iv,
      plaintext,
      @aad,
      true
    )
    
    # Combine iv, tag, and ciphertext
    Base.encode64(iv <> tag <> ciphertext)
  end
  
  @doc """
  Decrypt a base64-encoded ciphertext.
  
  Returns the plain text string.
  """
  def decrypt(ciphertext_b64) do
    key = get_encryption_key()
    
    case Base.decode64(ciphertext_b64) do
      {:ok, combined} ->
        # Extract iv (12 bytes), tag (16 bytes), ciphertext
        iv = binary_part(combined, 0, 12)
        tag = binary_part(combined, 12, 16)
        ciphertext = binary_part(combined, 28, byte_size(combined) - 28)
        
        :crypto.crypto_one_time_aead(
          :aes_256_gcm,
          key,
          iv,
          ciphertext,
          @aad,
          tag,
          false
        )
        
      :error ->
        {:error, :invalid_base64}
    end
  end
  
  defp get_encryption_key do
    key = System.get_env("ENCRYPTION_KEY") || 
      Application.get_env(:f_improve, :encryption_key)
    
    if is_binary(key) and byte_size(key) == 32 do
      key
    else
      raise "ENCRYPTION_KEY must be 32 bytes"
    end
  end
end