defmodule QlcDigital.Crypto do
  @moduledoc """
  AES-256-GCM envelope for values stored in Redis.

  Wire format: <<version::8, iv::96, tag::128, ciphertext::binary>>
  The version byte lets us rotate keys without a migration script.
  """

  @version 1
  @iv_size 12
  @tag_size 16

  @spec encrypt(binary()) :: binary()
  def encrypt(plaintext) when is_binary(plaintext) do
    iv = :crypto.strong_rand_bytes(@iv_size)
    aad = <<@version>>

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key(), iv, plaintext, aad, true)

    <<@version, iv::binary, tag::binary, ciphertext::binary>>
  end

  @spec decrypt(binary()) :: {:ok, binary()} | {:error, :invalid_ciphertext}
  def decrypt(<<@version, iv::binary-size(@iv_size), tag::binary-size(@tag_size), ct::binary>>) do
    aad = <<@version>>

    case :crypto.crypto_one_time_aead(:aes_256_gcm, key(), iv, ct, aad, tag, false) do
      plaintext when is_binary(plaintext) -> {:ok, plaintext}
      :error -> {:error, :invalid_ciphertext}
    end
  end

  def decrypt(_), do: {:error, :invalid_ciphertext}

  @spec envelope?(binary()) :: boolean()
  def envelope?(<<@version, _::binary>>), do: true
  def envelope?(_), do: false

  defp key do
    case Application.get_env(:qlc_digital, :encryption)[:key] do
      nil ->
        raise "encryption key not configured (set ENCRYPTION_KEY env var)"

      encoded ->
        case Base.decode64(encoded) do
          {:ok, <<key::binary-size(32)>>} -> key
          _ -> raise "ENCRYPTION_KEY must be base64-encoded 32 bytes"
        end
    end
  end
end
