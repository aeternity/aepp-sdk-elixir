defmodule UtilsKeysTest do
  use ExUnit.Case

  alias Utils.Keys

  @keys_path "./keys"

  setup_all do
    keypair = Keys.generate_keypair()
    %{public: pubkey, secret: privkey} = keypair
    pubkey_binary = Keys.pubkey_to_binary(pubkey)
    privkey_binary = Keys.privkey_to_binary(privkey)

    on_exit(fn ->
      File.rm_rf!(@keys_path)
    end)

    [
      keypair: keypair,
      pubkey: pubkey,
      pubkey_binary: pubkey_binary,
      privkey: privkey,
      privkey_binary: privkey_binary
    ]
  end

  test "save and read keys", keys do
    assert :ok == Keys.save_keypair(keys.keypair, "password123", "keypair1", @keys_path)
    assert {:ok, keys.keypair} == Keys.read_keypair("password123", "keypair1", @keys_path)

    # non-existent keys
    assert match?({:error, _reason}, Keys.read_keypair("password123", "keypair123", @keys_path))
  end

  test "signing", keys do
    signature = Keys.sign("message123", keys.privkey_binary)
    assert {:ok, "message123"} == Keys.verify(signature, "message123", keys.pubkey_binary)
  end

  test "encoding", keys do
    assert keys.pubkey == Keys.pubkey_from_binary(keys.pubkey_binary)
    assert keys.privkey == Keys.privkey_from_binary(keys.privkey_binary)
  end
end
