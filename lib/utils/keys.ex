defmodule AeppSDK.Utils.Keys do
  @moduledoc """
  Key generation, handling, encoding and crypto.
  """
  alias AeppSDK.Utils.Encoding
  alias Argon2.Base, as: Argon2Base

  @prefix_bits 24
  @random_salt_bytes 16
  @random_nonce_bytes 24
  @default_hash_params %{
    m_cost: 16,
    parallelism: 1,
    t_cost: 3,
    format: :raw_hash,
    argon2_type: 2
  }
  #  2^ 16 =  65536, 2^18 = 262144
  @default_kdf_params %{
    memlimit_kib: 65536,
    opslimit: 3,
    salt: "",
    parallelism: 1
  }

  @typedoc """
  A base58c encoded public key.
  """
  @type public_key :: Encoding.base58c()

  @typedoc """
  A hex encoded private key.
  """
  @type secret_key :: Encoding.hex()

  @type keypair :: %{public: public_key(), secret: secret_key()}

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

  ## Example
      iex> AeppSDK.Utils.Keys.generate_keypair()
      %{
        public: "ak_Q9DozPaq7fZ9WnB8SwNxuniaWwUmp1M7HsFTgCdJSsU2kKtC4",
        secret: "227bdeedb4c3dd2b554ea6b448ac6788fbe66df1b4f87093a450bba748f296f5348bd07453735393e2ff8c03c65b4593f3bdd94f957a2e7cb314688b53441280"
      }
  """
  @spec generate_keypair :: keypair()
  def generate_keypair do
    %{public: binary_public_key, secret: binary_secret_key} = :enacl.sign_keypair()

    %{
      public: public_key_from_binary(binary_public_key),
      secret: secret_key_from_binary(binary_secret_key)
    }
  end

  @doc """
  false
  """
  def generate_peer_keypair do
    %{public: peer_public_key, secret: peer_secret_key} = :enacl.sign_keypair()
    public = :enacl.crypto_sign_ed25519_public_to_curve25519(peer_public_key)
    secret = :enacl.crypto_sign_ed25519_secret_to_curve25519(peer_secret_key)
    %{public: public, secret: secret}
  end

  @spec get_pubkey_from_secret_key(String.t()) :: String.t()
  def get_pubkey_from_secret_key(secret_key) do
    <<_::size(256), pubkey::size(256)>> = Base.decode16!(secret_key, case: :lower)

    Encoding.prefix_encode_base58c("ak", :binary.encode_unsigned(pubkey))
  end

  @doc """
  Create a new keystore

  ## Example
      iex> secret = "227bdeedb4c3dd2b554ea6b448ac6788fbe66df1b4f87093a450bba748f296f5348bd07453735393e2ff8c03c65b4593f3bdd94f957a2e7cb314688b53441280"
      iex> AeppSDK.Utils.Keys.new_keystore(secret, "1234")
      :ok
  """
  @spec new_keystore(String.t(), String.t(), list()) :: :ok | {:error, atom}
  def new_keystore(secret_key, password, opts \\ []) do
    %{year: year, month: month, day: day, hour: hour, minute: minute, second: second} =
      DateTime.utc_now()

    time = "#{year}-#{month}-#{day}-#{hour}-#{minute}-#{second}"
    name = Keyword.get(opts, :name, time)
    keystore = create_keystore(secret_key, password, name)
    json = Poison.encode!(keystore)
    {:ok, file} = File.open(name, [:read, :write])
    IO.write(file, json)
    File.close(file)
  end

  @doc """
  Read the private key from the keystore

  ## Example:
      iex> AeppSDK.Utils.Keys.read_keystore("2019-10-25-9-48-48", "1234")
      "227bdeedb4c3dd2b554ea6b448ac6788fbe66df1b4f87093a450bba748f296f5348bd07453735393e2ff8c03c65b4593f3bdd94f957a2e7cb314688b53441280"
  """
  @spec read_keystore(String.t(), String.t()) :: binary() | {:error, atom()}
  def read_keystore(path, password) when is_binary(path) and is_binary(password) do
    with {:ok, json_keystore} <- File.read(path),
         {:ok, keystore} <- Poison.decode(json_keystore, keys: :atoms!),
         params = process_params(keystore),
         derived_key = derive_key_argon2(password, params.salt, params.kdf_params),
         {:ok, secret} <-
           decrypt(params.ciphertext, params.nonce, Base.decode16!(derived_key, case: :lower)) do
      Base.encode16(secret, case: :lower)
    else
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Sign a binary message with the given private key

  ## Example
      iex> message = "some message"
      iex> secret_key = <<34, 123, 222, 237, 180, 195, 221, 43, 85, 78, 166, 180, 72, 172, 103, 136,251, 230, 109, 241, 180, 248, 112, 147, 164, 80, 187, 167, 72, 242, 150, 245,52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243,189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
      iex> AeppSDK.Utils.Keys.sign(message, secret_key)
      <<94, 26, 208, 168, 230, 154, 158, 226, 188, 217, 155, 170, 157, 33, 100, 22,
      247, 171, 91, 120, 249, 52, 147, 194, 188, 1, 14, 5, 15, 166, 232, 202, 97,
      96, 32, 32, 227, 151, 158, 216, 22, 68, 219, 5, 169, 229, 117, 147, 179, 43,
      172, 211, 243, 171, 234, 254, 210, 119, 105, 248, 154, 19, 202, 7>>
  """
  @spec sign(binary(), binary()) :: signature()
  def sign(message, secret_key), do: :enacl.sign_detached(message, secret_key)

  @doc """
  Prefixes a network ID string to a binary message and signs it with the given private key

  ## Example
      iex> message = "some message"
      iex> secret_key = <<34, 123, 222, 237, 180, 195, 221, 43, 85, 78, 166, 180, 72, 172, 103, 136,251, 230, 109, 241, 180, 248, 112, 147, 164, 80, 187, 167, 72, 242, 150, 245,52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243,189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
      iex> AeppSDK.Utils.Keys.sign(message, secret_key, "ae_uat")
      <<15, 246, 136, 55, 63, 30, 144, 154, 249, 161, 243, 93, 52, 0, 218, 22, 43,
      200, 145, 252, 247, 218, 197, 125, 177, 17, 60, 177, 212, 106, 249, 130, 42,
      179, 233, 174, 116, 145, 154, 244, 80, 48, 142, 153, 170, 34, 199, 219, 248,
      107, 115, 155, 254, 69, 37, 68, 68, 1, 174, 95, 102, 10, 6, 14>>
  """
  @spec sign(binary(), binary(), String.t()) :: signature()
  def sign(message, secret_key, network_id),
    do: :enacl.sign_detached(network_id <> message, secret_key)

  @doc """
  Verify that a message has been signed by a private key corresponding to the given public key

  ## Example
      iex> signature = <<94, 26, 208, 168, 230, 154, 158, 226, 188, 217, 155, 170, 157, 33, 100, 22, 247, 171, 91, 120, 249, 52, 147, 194, 188, 1, 14, 5, 15, 166, 232, 202, 97, 96, 32, 32, 227, 151, 158, 216, 22, 68, 219, 5, 169, 229, 117, 147, 179, 43, 172, 211, 243, 171, 234, 254, 210, 119, 105, 248, 154, 19, 202, 7>>
      iex> message = "some message"
      iex> public_key = <<52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243, 189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
      iex> AeppSDK.Utils.Keys.verify(signature, message, public_key)
      {:ok, "some message"}
  """
  @spec verify(message(), signature(), binary()) :: {:ok, message()} | {:error, atom()}
  def verify(signature, message, public_key),
    do: :enacl.sign_verify_detached(signature, message, public_key)

  @doc """
  Save a keypair at a given path with the specified file name. The keys are encrypted with the password and saved as separate files - `name` for the private and `{
    name
  }.pub` for the public key

  ## Example
      iex> keypair = AeppSDK.Utils.Keys.generate_keypair()
      iex> password = "some password"
      iex> path = "./keys"
      iex> name = "key"
      iex> AeppSDK.Utils.Keys.save_keypair(keypair, password, path, name)
      :ok
  """
  @spec save_keypair(keypair(), password(), String.t(), String.t()) :: :ok | {:error, String.t()}
  def save_keypair(%{public: public_key, secret: secret_key}, password, path, name) do
    binary_public_key = public_key_to_binary(public_key)
    binary_secret_key = secret_key_to_binary(secret_key)

    public_key_path = Path.join(path, "#{name}.pub")

    secret_key_path = Path.join(path, name)

    case mkdir(path) do
      :ok ->
        case {File.write(public_key_path, encrypt_key(binary_public_key, password)),
              File.write(secret_key_path, encrypt_key(binary_secret_key, password))} do
          {:ok, :ok} ->
            :ok

          {{:error, public_key_reason}, {:error, secret_key_reason}} ->
            {:error,
             "Couldn't write public (#{Atom.to_string(public_key_reason)}) or private key (#{
               Atom.to_string(secret_key_reason)
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

  ## Example
      iex> password = "some password"
      iex> path = "./keys"
      iex> name = "key"
      iex> AeppSDK.Utils.Keys.read_keypair(password, path, name)
      {:ok,
       %{
         public: "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb",
         secret: "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
       }}
  """
  @spec read_keypair(password(), String.t(), String.t()) ::
          {:ok, keypair()} | {:error, String.t()}
  def read_keypair(password, path, name) do
    public_key_read = path |> Path.join("#{name}.pub") |> File.read()
    secret_key_read = path |> Path.join("#{name}") |> File.read()

    case {public_key_read, secret_key_read} do
      {{:ok, encrypted_public_key}, {:ok, encrypted_secret_key}} ->
        public_key = encrypted_public_key |> decrypt_key(password) |> public_key_from_binary()
        secret_key = encrypted_secret_key |> decrypt_key(password) |> secret_key_from_binary()

        {:ok, %{public: public_key, secret: secret_key}}

      {{:error, public_key_reason}, {:error, secret_key_reason}} ->
        {:error,
         "Couldn't read public (reason: #{Atom.to_string(public_key_reason)}) or private key (reason: #{
           Atom.to_string(secret_key_reason)
         }) from #{path}"}

      {{:error, reason}, {:ok, _}} ->
        {:error, "Couldn't read public key from #{path}: #{Atom.to_string(reason)} "}

      {{:ok, _}, {:error, reason}} ->
        {:error, "Couldn't read private key from #{path}: #{Atom.to_string(reason)}"}
    end
  end

  @doc """
  Convert a base58check public key string to binary

  ## Example
      iex> public_key = "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
      iex> AeppSDK.Utils.Keys.public_key_to_binary(public_key)
      <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
      ```
  """
  @spec public_key_to_binary(public_key()) :: binary()
  def public_key_to_binary(public_key), do: Encoding.prefix_decode_base58c(public_key)

  @doc """
  Convert a base58check public key string to tuple of prefix and binary

  ## Example
      iex> public_key = "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
      iex> AeppSDK.Utils.Keys.public_key_to_binary(public_key, :with_prefix)
      {"ak_",
       <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190,
         47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>}
      ```
  """
  @spec public_key_to_binary(public_key(), atom()) :: tuple()
  def public_key_to_binary(<<prefix::@prefix_bits, _payload::binary>> = public_key, :with_prefix),
    do: {<<prefix::@prefix_bits>>, Encoding.prefix_decode_base58c(public_key)}

  @doc """
  Convert a binary public key to a base58check string

  ## Example
      iex> binary_public_key = <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
      iex> AeppSDK.Utils.Keys.public_key_from_binary(binary_public_key)
      "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
  """
  @spec public_key_from_binary(binary()) :: public_key()
  def public_key_from_binary(binary_public_key),
    do: Encoding.prefix_encode_base58c("ak", binary_public_key)

  @doc """
  Convert a hex string private key to binary

  ## Example
      iex> secret_key = "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
      iex> AeppSDK.Utils.Keys.secret_key_to_binary(secret_key)
      <<249, 206, 190, 135, 77, 144, 98, 107, 252, 234, 16, 147, 231, 47, 34, 229, 0,
      169, 46, 149, 5, 43, 136, 170, 235, 213, 211, 3, 70, 19, 44, 177, 253, 16,
      150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157,
      115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
  """
  @spec secret_key_to_binary(secret_key()) :: binary()
  def secret_key_to_binary(secret_key) do
    Base.decode16!(secret_key, case: :lower)
  end

  @doc """
  Convert a binary private key to a hex string

  ## Example
      iex> binary_secret_key = <<249, 206, 190, 135, 77, 144, 98, 107, 252, 234, 16, 147, 231, 47, 34, 229, 0, 169, 46, 149, 5, 43, 136, 170, 235, 213, 211, 3, 70, 19, 44, 177, 253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
      iex> AeppSDK.Utils.Keys.secret_key_from_binary(binary_secret_key)
      "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
  """
  @spec secret_key_from_binary(binary()) :: secret_key()
  def secret_key_from_binary(binary_secret_key) do
    Base.encode16(binary_secret_key, case: :lower)
  end

  defp process_params(%{
         crypto: %{
           cipher_params: %{nonce: nonce},
           ciphertext: ciphertext,
           kdf: kdf,
           kdf_params: %{
             memlimit_kib: memlimit,
             opslimit: opslimit,
             parallelism: parallelism,
             salt: salt
           }
         }
       }) do
    kdf_algorithm = process_param(kdf)
    m_cost = memlimit |> :math.log2() |> round
    t_cost = opslimit
    decoded_salt = Base.decode16!(salt, case: :lower)
    decoded_ciphertext = Base.decode16!(ciphertext, case: :lower)
    decoded_nonce = Base.decode16!(nonce, case: :lower)

    %{
      kdf_params: %{
        m_cost: m_cost,
        t_cost: t_cost,
        parallelism: parallelism,
        argon2_type: kdf_algorithm
      },
      salt: decoded_salt,
      ciphertext: decoded_ciphertext,
      nonce: decoded_nonce
    }
  end

  defp process_param("argon2d") do
    0
  end

  defp process_param("argon2i") do
    1
  end

  defp process_param("argon2id") do
    2
  end

  defp encrypt(plaintext, nonce, derived_key) do
    :enacl.secretbox(plaintext, nonce, derived_key)
  end

  defp decrypt(ciphertext, nonce, derived_key)
       when is_binary(ciphertext) and byte_size(nonce) == 24 and byte_size(derived_key) == 32 do
    :enacl.secretbox_open(ciphertext, nonce, derived_key)
  end

  defp decrypt(_, _, _) do
    {:error, "#{__MODULE__}: Invalid data"}
  end

  defp create_keystore(secret_key, password, name \\ "")
       when is_binary(secret_key) and is_binary(password) do
    salt = :enacl.randombytes(@random_salt_bytes)
    nonce = :enacl.randombytes(@random_nonce_bytes)
    derived_key = derive_key_argon2(password, salt, @default_hash_params)

    encrypted_key =
      encrypt(secret_key_to_binary(secret_key), nonce, Base.decode16!(derived_key, case: :lower))

    %{
      public_key: get_pubkey_from_secret_key(secret_key),
      crypto: %{
        secret_type: "ed25519",
        symmetric_alg: "xsalsa20-poly1305",
        ciphertext: Base.encode16(encrypted_key, case: :lower),
        cipher_params: %{
          nonce: Base.encode16(nonce, case: :lower)
        },
        kdf: "argon2id",
        kdf_params: %{@default_kdf_params | salt: Base.encode16(salt, case: :lower)}
      },
      id: UUID.uuid4(),
      name: name,
      version: 1
    }
  end

  defp derive_key_argon2(
         password,
         salt,
         %{
           memlimit_kib: memlimit_kib,
           opslimit: opslimit,
           salt: salt,
           parallelism: parallelism
         }
       ) do
    derive_key_argon2(password, salt, %{
      m_cost: memlimit_kib |> :math.log2() |> round(),
      parallelism: parallelism,
      t_cost: opslimit
    })
  end

  defp derive_key_argon2(password, salt, kdf_params) do
    processed_kdf_params =
      for kdf_param <- Map.keys(@default_hash_params), reduce: %{} do
        acc ->
          Map.put(
            acc,
            kdf_param,
            Map.get(kdf_params, kdf_param, Map.get(@default_hash_params, kdf_param))
          )
      end

    Argon2Base.hash_password(password, salt, Enum.into(processed_kdf_params, []))
  end

  defp mkdir(path) do
    if File.exists?(path) do
      :ok
    else
      File.mkdir(path)
    end
  end

  defp encrypt_key(key, password), do: :crypto.block_encrypt(:aes_ecb, hash(password), key)

  defp decrypt_key(encrypted, password),
    do: :crypto.block_decrypt(:aes_ecb, hash(password), encrypted)

  defp hash(binary), do: :crypto.hash(:sha256, binary)
end
