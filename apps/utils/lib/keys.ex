defmodule Utils.Keys do
  alias Utils.Encoding

  @type pubkey :: Encoding.base58c()
  @type privkey :: Encoding.hex()
  @type keypair :: %{public: pubkey(), secret: privkey()}

  @type message :: binary()
  @type signature :: binary()

  @type password :: String.t()

  @spec generate_keypair :: keypair()
  def generate_keypair do
    %{public: binary_pubkey, secret: binary_privkey} = :enacl.sign_keypair()
    %{public: pubkey_from_binary(binary_pubkey), secret: privkey_from_binary(binary_privkey)}
  end

  @spec sign(binary(), privkey()) :: signature()
  def sign(message, privkey), do: :enacl.sign_detached(message, privkey)

  @spec verify(message(), signature(), binary()) :: boolean()
  def verify(signature, message, pubkey),
    do: :enacl.sign_verify_detached(signature, message, pubkey)

  @spec read_keypair(password(), String.t(), String.t()) ::
          {:ok, keypair()} | {:error, String.t()}
  def read_keypair(password, name, path) do
    pubkey_read = path |> Path.join("#{name}.pub") |> File.read()
    privkey_read = path |> Path.join("#{name}") |> File.read()

    case {pubkey_read, privkey_read} do
      {{:ok, encrypted_pubkey}, {:ok, encrypted_privkey}} ->
        pubkey = encrypted_pubkey |> decrypt_key(password) |> pubkey_from_binary()
        privkey = encrypted_privkey |> decrypt_key(password) |> privkey_from_binary()

        {:ok, %{public: pubkey, secret: privkey}}

      {{:error, pubkey_reason}, {:error, privkey_reason}} ->
        {:error,
         "Couldn't read public (reason: #{Atom.to_string(pubkey_reason)}) or private key (reason: #{
           Atom.to_string(privkey_reason)
         }) from #{path}"}

      {{:error, reason}, {:ok, _}} ->
        {:error, "Couldn't read public key from #{path}: #{Atom.to_string(reason)} "}

      {{:ok, _}, {:error, reason}} ->
        {:error, "Couldn't read private key from #{path}: #{Atom.to_string(reason)}"}
    end
  end

  @spec save_keypair(keypair(), password(), String.t(), String.t()) :: :ok | {:error, String.t()}
  def save_keypair(%{public: pubkey, secret: privkey}, password, name, path) do
    binary_pubkey = pubkey_to_binary(pubkey)
    binary_privkey = privkey_to_binary(privkey)

    pubkey_write =
      path |> Path.join("#{name}.pub") |> File.write(encrypt_key(binary_pubkey, password))

    privkey_write = path |> Path.join(name) |> File.write(encrypt_key(binary_privkey, password))

    case mkdir(path) do
      :ok ->
        case {pubkey_write, privkey_write} do
          {:ok, :ok} ->
            :ok

          {{:error, pubkey_reason}, {:error, privkey_reason}} ->
            {:error,
             "Couldn't write public (#{Atom.to_string(pubkey_reason)}) or private key (#{
               Atom.to_string(privkey_reason)
             } in #{path})"}

          {{:error, reason}, {:ok, _}} ->
            {:error, "Couldn't write public key in #{path}: #{Atom.to_string(reason)}"}

          {{:ok, _}, {:error, reason}} ->
            {:error, "Couldn't write private key in #{path}: #{Atom.to_string(reason)}"}
        end

      {:error, reason} ->
        {:error, "Couldn't create directory #{path}: #{Atom.to_string(reason)}"}
    end
  end

  @spec pubkey_from_binary(binary()) :: pubkey()
  def pubkey_from_binary(binary_pubkey), do: Encoding.binary_to_base58c("ak", binary_pubkey)

  @spec pubkey_to_binary(pubkey()) :: binary()
  def pubkey_to_binary(pubkey), do: Encoding.base58c_to_binary(pubkey)

  @spec privkey_from_binary(binary()) :: privkey()
  def privkey_from_binary(binary_privkey) do
    <<integer_privkey::512>> = binary_privkey

    integer_privkey
    |> Integer.to_string(16)
    |> String.downcase()
  end

  @spec privkey_to_binary(privkey()) :: binary()
  def privkey_to_binary(privkey) do
    {integer_privkey, _} = Integer.parse(privkey, 16)
    :binary.encode_unsigned(integer_privkey)
  end

  defp mkdir(path) do
    if !File.exists?(path) do
      File.mkdir(path)
    else
      :ok
    end
  end

  defp encrypt_key(key, password), do: :crypto.block_encrypt(:aes_ecb, hash(password), key)

  defp decrypt_key(encrypted, password),
    do: :crypto.block_decrypt(:aes_ecb, hash(password), encrypted)

  defp hash(binary), do: :crypto.hash(:sha256, binary)
end
