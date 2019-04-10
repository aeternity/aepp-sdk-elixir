defmodule Utils.Keys do
  @moduledoc """
  Key generation, handling, encoding and crypto
  """
  alias Utils.Encoding

  @hex_base 16

  @typedoc """
  A base58c encoded public key.
  """
  @type pubkey :: Encoding.base58c()
  @prefix_bits 24

  @typedoc """
  A hex encoded prviate key.
  """
  @type privkey :: Encoding.hex()

  @type keypair :: %{public: pubkey(), secret: privkey()}

  @typedoc """
  An arbitrary binary message.
  """
  @type message :: binary()
  @type signature :: binary()

  @typedoc """
  An arbitrary string password.
  """
  @type password :: String.t()

  @doc """
  Generate a Curve25519 keypair

  ## Examples
      iex> Utils.Keys.generate_keypair()
      %{
        public: "ak_Q9DozPaq7fZ9WnB8SwNxuniaWwUmp1M7HsFTgCdJSsU2kKtC4",
        secret: "227bdeedb4c3dd2b554ea6b448ac6788fbe66df1b4f87093a450bba748f296f5348bd07453735393e2ff8c03c65b4593f3bdd94f957a2e7cb314688b53441280"
      }
  """

  @spec generate_keypair :: keypair()
  def generate_keypair do
    %{public: binary_pubkey, secret: binary_privkey} = :enacl.sign_keypair()
    %{public: pubkey_from_binary(binary_pubkey), secret: privkey_from_binary(binary_privkey)}
  end

  @doc """
  Sign a binary message with the given private key

  ## Examples
      iex> message = "some message"
      iex> privkey = <<34, 123, 222, 237, 180, 195, 221, 43, 85, 78, 166, 180, 72, 172, 103, 136,251, 230, 109, 241, 180, 248, 112, 147, 164, 80, 187, 167, 72, 242, 150, 245,52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243,189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
      iex> Utils.Keys.sign(message, privkey)
      <<94, 26, 208, 168, 230, 154, 158, 226, 188, 217, 155, 170, 157, 33, 100, 22,
      247, 171, 91, 120, 249, 52, 147, 194, 188, 1, 14, 5, 15, 166, 232, 202, 97,
      96, 32, 32, 227, 151, 158, 216, 22, 68, 219, 5, 169, 229, 117, 147, 179, 43,
      172, 211, 243, 171, 234, 254, 210, 119, 105, 248, 154, 19, 202, 7>>
  """

  @spec sign(binary(), binary()) :: signature()
  def sign(message, privkey), do: :enacl.sign_detached(message, privkey)

  @doc """
  Verify that a message has been signed by a private key corresponding to the given public key

  ## Examples
      iex> signature = <<94, 26, 208, 168, 230, 154, 158, 226, 188, 217, 155, 170, 157, 33, 100, 22, 247, 171, 91, 120, 249, 52, 147, 194, 188, 1, 14, 5, 15, 166, 232, 202, 97, 96, 32, 32, 227, 151, 158, 216, 22, 68, 219, 5, 169, 229, 117, 147, 179, 43, 172, 211, 243, 171, 234, 254, 210, 119, 105, 248, 154, 19, 202, 7>>
      iex> message = "some message"
      iex> pubkey = <<52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243, 189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
      iex> Utils.Keys.verify(signature, message, pubkey)
      {:ok, "some message"}
  """
  @spec verify(message(), signature(), binary()) :: {:ok, message()} | {:error, atom()}
  def verify(signature, message, pubkey),
    do: :enacl.sign_verify_detached(signature, message, pubkey)

  @doc """
  Save a keypair at a given path with the specified file name. The keys are encrypted with the password and saved as separate files - `name` for the private and `{
    name
  }.pub` for the public key

  ## Examples
      iex> keypair = Utils.Keys.generate_keypair()
      iex> password = "some password"
      iex> path = "./keys"
      iex> name = "key"
      iex> Utils.Keys.save_keypair(keypair, password, path, name)
      :ok
  """
  @spec save_keypair(keypair(), password(), String.t(), String.t()) :: :ok | {:error, String.t()}
  def save_keypair(%{public: pubkey, secret: privkey}, password, path, name) do
    binary_pubkey = pubkey_to_binary(pubkey)
    binary_privkey = privkey_to_binary(privkey)

    pubkey_path = Path.join(path, "#{name}.pub")

    privkey_path = Path.join(path, name)

    case mkdir(path) do
      :ok ->
        case {File.write(pubkey_path, encrypt_key(binary_pubkey, password)),
              File.write(privkey_path, encrypt_key(binary_privkey, password))} do
          {:ok, :ok} ->
            :ok

          {{:error, pubkey_reason}, {:error, privkey_reason}} ->
            {:error,
             "Couldn't write public (#{Atom.to_string(pubkey_reason)}) or private key (#{
               Atom.to_string(privkey_reason)
             } in #{path})"}

          {{:error, reason}, :ok} ->
            {:error, "Couldn't write public key in #{path}: #{Atom.to_string(reason)}"}

          {:ok, {:error, reason}} ->
            {:error, "Couldn't write private key in #{path}: #{Atom.to_string(reason)}"}
        end

      {:error, reason} ->
        {:error, "Couldn't create directory #{path}: #{Atom.to_string(reason)}"}
    end
  end

  @doc """
  Attempt to read a keypair from a given path with the specified file name. If found, the keys will be decrypted with the password

  ## Examples
      iex> password = "some password"
      iex> path = "./keys"
      iex> name = "key"
      iex> Utils.Keys.read_keypair(password, path, name)
      {:ok,
       %{
         public: "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb",
         secret: "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
       }}
  """
  @spec read_keypair(password(), String.t(), String.t()) ::
          {:ok, keypair()} | {:error, String.t()}
  def read_keypair(password, path, name) do
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

  @doc """
  Convert a base58check public key string to binary

  ## Examples
      iex> pubkey = "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
      iex> Utils.Keys.pubkey_to_binary(pubkey)
      <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
      ```
  """

  @spec pubkey_to_binary(pubkey()) :: binary()
  def pubkey_to_binary(pubkey), do: Encoding.prefix_decode_base58c(pubkey)

  @doc """
  Convert a base58check public key string to tuple of prefix and binary

  ## Examples
      iex> pubkey = "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
      iex> Utils.Keys.pubkey_to_binary(pubkey, :with_prefix)
      {"ak_",
       <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190,
         47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>}
      ```
  """
  @spec pubkey_to_binary(pubkey(), atom()) :: tuple()
  def pubkey_to_binary(<<prefix::@prefix_bits, _payload::binary>> = pubkey, :with_prefix),
    do: {<<prefix::@prefix_bits>>, Encoding.prefix_decode_base58c(pubkey)}

  @doc """
  Convert a binary public key to a base58check string

  ## Examples
      iex> binary_pubkey = <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
      iex> Utils.Keys.pubkey_from_binary(binary_pubkey)
      "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
  """
  @spec pubkey_from_binary(binary()) :: pubkey()
  def pubkey_from_binary(binary_pubkey), do: Encoding.prefix_encode_base58c("ak", binary_pubkey)

  @doc """
  Convert a hex string private key to binary

  ## Examples
      iex> privkey = "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
      iex> Utils.Keys.privkey_to_binary(privkey)
      <<249, 206, 190, 135, 77, 144, 98, 107, 252, 234, 16, 147, 231, 47, 34, 229, 0,
      169, 46, 149, 5, 43, 136, 170, 235, 213, 211, 3, 70, 19, 44, 177, 253, 16,
      150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157,
      115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
  """
  @spec privkey_to_binary(privkey()) :: binary()
  def privkey_to_binary(privkey) do
    {integer_privkey, _} = Integer.parse(privkey, @hex_base)
    :binary.encode_unsigned(integer_privkey)
  end

  @doc """
  Convert a binary private key to a hex string

  ## Examples
      iex> binary_privkey = <<249, 206, 190, 135, 77, 144, 98, 107, 252, 234, 16, 147, 231, 47, 34, 229, 0, 169, 46, 149, 5, 43, 136, 170, 235, 213, 211, 3, 70, 19, 44, 177, 253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
      iex> Utils.Keys.privkey_from_binary(binary_privkey)
      "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
  """

  @spec privkey_from_binary(binary()) :: privkey()
  def privkey_from_binary(binary_privkey) do
    binary_privkey
    |> :binary.decode_unsigned()
    |> Integer.to_string(@hex_base)
    |> String.downcase()
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
