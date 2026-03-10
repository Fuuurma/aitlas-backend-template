defmodule Aitlas.CryptoTest do
  use ExUnit.Case, async: true

  alias Aitlas.Crypto

  describe "encrypt/1 and decrypt/2" do
    test "encrypts and decrypts a string" do
      plaintext = "sk-test-api-key-12345"

      {encrypted, iv} = Crypto.encrypt(plaintext)
      decrypted = Crypto.decrypt(encrypted, iv)

      assert decrypted == plaintext
    end

    test "produces different ciphertext for same input (random IV)" do
      plaintext = "same-key"

      {encrypted1, iv1} = Crypto.encrypt(plaintext)
      {encrypted2, iv2} = Crypto.encrypt(plaintext)

      assert encrypted1 != encrypted2
      assert iv1 != iv2

      assert Crypto.decrypt(encrypted1, iv1) == plaintext
      assert Crypto.decrypt(encrypted2, iv2) == plaintext
    end

    test "handles empty string" do
      plaintext = ""

      {encrypted, iv} = Crypto.encrypt(plaintext)
      decrypted = Crypto.decrypt(encrypted, iv)

      assert decrypted == plaintext
    end

    test "handles long strings" do
      plaintext = String.duplicate("x", 10_000)

      {encrypted, iv} = Crypto.encrypt(plaintext)
      decrypted = Crypto.decrypt(encrypted, iv)

      assert decrypted == plaintext
    end

    test "handles unicode characters" do
      plaintext = "日本語テスト 🎉"

      {encrypted, iv} = Crypto.encrypt(plaintext)
      decrypted = Crypto.decrypt(encrypted, iv)

      assert decrypted == plaintext
    end

    test "raises on invalid ciphertext" do
      {_, iv} = Crypto.encrypt("test")

      assert_raise ArgumentError, fn ->
        Crypto.decrypt("invalid-base64!!!", iv)
      end
    end

    test "raises on invalid IV" do
      {encrypted, _} = Crypto.encrypt("test")

      assert_raise ArgumentError, fn ->
        Crypto.decrypt(encrypted, "invalid-iv!!!")
      end
    end
  end
end
