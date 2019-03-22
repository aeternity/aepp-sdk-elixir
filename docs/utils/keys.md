# Utils.Keys

#### `generate_keypair() :: %{public: String.t(), secret: String.t()}`

Generate a Curve25519 keypair

***Example:***
```elixir
iex> Utils.Keys.generate_keypair()
%{
  public: "ak_Q9DozPaq7fZ9WnB8SwNxuniaWwUmp1M7HsFTgCdJSsU2kKtC4",
  secret: "227bdeedb4c3dd2b554ea6b448ac6788fbe66df1b4f87093a450bba748f296f5348bd07453735393e2ff8c03c65b4593f3bdd94f957a2e7cb314688b53441280"
}
```

___

#### `sign(message, privkey) :: binary()`

Sign a binary message with the given private key

| Param | Type | Description |
| --- | --- | --- |
| message | `binary()` | Message to be signed |
| privkey | `binary()` | Private key to sign the message with |

***Example:***
```elixir
iex> message = "some message"
iex> privkey = <<34, 123, 222, 237, 180, 195, 221, 43, 85, 78, 166, 180, 72, 172, 103, 136,251, 230, 109, 241, 180, 248, 112, 147, 164, 80, 187, 167, 72, 242, 150, 245,52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243,189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
iex> Utils.Keys.sign(message, privkey)
<<94, 26, 208, 168, 230, 154, 158, 226, 188, 217, 155, 170, 157, 33, 100, 22,247, 171, 91, 120, 249, 52, 147, 194, 188, 1, 14, 5, 15, 166, 232, 202, 97,96, 32, 32, 227, 151, 158, 216, 22, 68, 219, 5, 169, 229, 117, 147, 179, 43,...>>
```

___

#### `verify(signature, message, pubkey) :: {:ok, binary()} | {:error, atom()}`

Verify that a message has been signed by a private key corresponding to the given public key

| Param | Type | Description |
| --- | --- | --- |
| signature | `binary()` | Signature to be verified |
| message | `binary()` | Message that was signed |
| pubkey | `binary()` | Public key to be verified with |

***Example:***
```elixir
iex> signature = <<94, 26, 208, 168, 230, 154, 158, 226, 188, 217, 155, 170, 157, 33, 100, 22, 247, 171, 91, 120, 249, 52, 147, 194, 188, 1, 14, 5, 15, 166, 232, 202, 97, 96, 32, 32, 227, 151, 158, 216, 22, 68, 219, 5, 169, 229, 117, 147, 179, 43, 172, 211, 243, 171, 234, 254, 210, 119, 105, 248, 154, 19, 202, 7>>
iex> message = "some message"
iex> pubkey = <<52, 139, 208, 116, 83, 115, 83, 147, 226, 255, 140, 3, 198, 91, 69, 147, 243, 189, 217, 79, 149, 122, 46, 124, 179, 20, 104, 139, 83, 68, 18, 128>>
iex> verify(signature, message, pubkey)
{:ok, "some message"}
```

___

#### `save_keypair(%{public: pubkey, secret: privkey}, password, path, name) :: :ok | {:error, String.t()}`

Save a keypair at a given path with the specified file name. The keys are encrypted with the password and saved as separate files - `name` for the private and `#{name}.pub` for the public key

| Param | Type | Description |
| --- | --- | --- |
| keypair | `%{public: String.t(), secret: String.t()}` | Keypair to be saved where the public key is a base58check string and the private key is a hex string |
| password | `String.t()` | Password to encrypt the keys with |
| path | `String.t()` | Path for the files to be saved at |
| name | `String.t()` | Name for the files to be saved with |


***Example:***
```elixir
iex> keypair = Utils.Keys.generate_keypair
%{
  public: "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb",
  secret: "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
}
iex> password = "some password"
iex> path = "./keys"
iex> name = "key"
iex> Utils.Keys.save_keypair(keypair, password, path, name)
:ok
```

___

#### `read_keypair(password, path, name) :: {:ok, %{public: String.t(), secret: String.t()}} | {:error, String.t()}`

Attempt to read a keypair from a given path with the specified file name. If found, the keys will be decrypted with the password

| Param | Type | Description |
| --- | --- | --- |
| password | `String.t()` | Password to decrypt the keys with |
| path | `String.t()` | Path to read from
| name | `String.t()` | Name of the files to read from |

***Example:***
```elixir
iex> password = "some password"
iex> path = "./keys"
iex> name = "key"
iex> Utils.Keys.read_keypair(password, path, name)
{:ok,
 %{
   public: "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb",
   secret: "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
 }}
```

___

#### `pubkey_to_binary(pubkey) :: String.t()`

Convert a base58check string to binary

| Param | Type | Description |
| --- | --- | --- |
| pubkey | `binary()` | base58check string public key to be converted |

***Example:***
```elixir
iex> pubkey = "ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
iex> Utils.Keys.pubkey_to_binary(pubkey)
<<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
```

___

#### `pubkey_from_binary(binary_pubkey) :: String.t()`

Convert a binary public key to a base58check string

| Param | Type | Description |
| --- | --- | --- |
| binary_pubkey | `binary()` | Binary public key to be converted |

***Example:***
```elixir
iex> binary_pubkey = <<253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
iex> Utils.Keys.pubkey_from_binary(binary_pubkey)
"ak_2vTCdFVAvgkYUDiVpydmByybqSYZHEB189QcfjmdcxRef2W2eb"
```

___

#### `privkey_to_binary(privkey) :: binary()`

Convert a hex string private key to binary

| Param | Type | Description |
| --- | --- | --- |
| privkey | `String.t()` | Hex string private key to be converted |

***Example:***
```elixir
iex> privkey = "f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
iex> Utils.Keys.privkey_to_binary(privkey)
<<249, 206, 190, 135, 77, 144, 98, 107, 252, 234, 16, 147, 231, 47, 34, 229, 0, 169, 46, 149, 5, 43, 136, 170, 235, 213, 211, 3, 70, 19, 44, 177, 253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, ...>>
```

___

#### `privkey_from_binary(binary_privkey) :: String.t()`

Convert a binary private key to a hex string

| Param | Type | Description |
| --- | --- | --- |
| binary_privkey | `binary()` | Binary private key to be converted |

***Example:***
```elixir
iex> binary_privkey = <<249, 206, 190, 135, 77, 144, 98, 107, 252, 234, 16, 147, 231, 47, 34, 229, 0, 169, 46, 149, 5, 43, 136, 170, 235, 213, 211, 3, 70, 19, 44, 177, 253, 16, 150, 32, 125, 62, 136, 112, 145, 227, 193, 26, 149, 60, 2, 56, 190, 47, 157, 115, 126, 32, 118, 191, 137, 134, 107, 183, 134, 188, 15, 191>>
iex> Utils.Keys.privkey_from_binary(binary_privkey)
"f9cebe874d90626bfcea1093e72f22e500a92e95052b88aaebd5d30346132cb1fd1096207d3e887091e3c11a953c0238be2f9d737e2076bf89866bb786bc0fbf"
```
