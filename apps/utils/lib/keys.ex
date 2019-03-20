defmodule Utils.Keys do

  @typedoc "Public key for signing or for peers - 32 bytes in size"
  @type pubkey :: binary()

  @typedoc "Private key for signing - 64 bytes in size"
  @type privkey :: binary()

  @type message :: binary()
  @type signature :: binary()

  @spec sign(message(), privkey()) :: signature()
  def sign(message, privkey) when is_binary(message) and is_binary(privkey) do
    :enacl.sign_detached(message, privkey)
  end

  def generate_keypair, do: :enacl.sign_keypair()

  def read_keypair(password, pubkey_path, privkey_path) do
    case {File.read(pubkey_path), File.read(privkey_path)} do
      {{:ok, encrypted_pubkey}, {:ok, encrypted_privkey}} ->
        pubkey = decrypt_key(encrypted_pubkey, password)
        privkey = decrypt_key(encrypted_privkey, password)

        %{public: pubkey, secret: privkey}
      _ ->
        {:error, :enoent}
    end
  end

  def save_keypair(password, pubkey_path, pubkey, privkey_path, privkey) do
    File.write!(pubkey_path, encrypt_key(pubkey, password))
    File.write!(privkey_path, encrypt_key(privkey, password))
  end

  defp encrypt_key(key, password), do: :crypto.block_encrypt(:aes_ecb, hash(password), key)

  defp decrypt_key(encrypted, password), do: :crypto.block_decrypt(:aes_ecb, hash(password), encrypted)

  defp hash(binary), do: :crypto.hash(:sha256, binary)

end
