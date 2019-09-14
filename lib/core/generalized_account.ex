defmodule AeppSDK.GeneralizedAccount do
  @moduledoc """
  Contains all generalized accounts functionalities.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.

  For more information: [https://github.com/aeternity/protocol/blob/master/generalized_accounts/generalized_accounts.md](https://github.com/aeternity/protocol/blob/master/generalized_accounts/generalized_accounts.md)
  """

  alias AeppSDK.{Client, Contract}
  alias AeppSDK.Utils.Account, as: AccountUtils
  alias AeppSDK.Utils.{Encoding, Hash, Serialization, Transaction}
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Model.Error

  @ct_version 0x40001
  @init_function "init"
  @default_gas 50_000

  @doc """
  Attach a generalized account to a basic account. After a generalized account has been attached, it's possible
  pass an :auth option to transaction related functions in order to authorize them through the attached contract.
  A transaction is authorized whenever the call to the auth function returns true (and unauthorized when false).

  The option looks like this:
  auth: [
    auth_contract_source: "contract Authorization =

      function auth(auth_value : bool) =
        auth_value",
    auth_args: ["true"],
    fee: 1_000_000_000_000_00,
    gas: 50_000,
    gas_price: 1_000_000_000,
    ttl: 0
  ]
  where gas, gas_price and ttl are optional.

  ## Examples
      iex> source_code = "contract Authorization =

        function auth(auth_value : bool) =
          auth_value"
      iex> auth_fun = "auth"
      iex> init_args = []
      iex> AeppSDK.GeneralizedAccount.attach(client, source_code, auth_fun, init_args)
      {:ok,
       %{
         block_hash: "mh_CfEuHm4V2omAQGNAxcdPARrkfnYbKuuF1HpGhG5oQvoVC34nD",
         block_height: 92967,
         tx_hash: "th_9LutrWD1FuFyx4MUUeMcfyF3uebfaP8t5gzatWDLyFYsqK744"
       }}
  """
  @spec attach(Client.t(), String.t(), String.t(), list(String.t()), list()) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c()
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def attach(
        %Client{
          keypair: %{public: public_key},
          connection: connection
        } = client,
        source_code,
        auth_fun,
        init_args,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, public_key),
         {:ok, %{byte_code: byte_code, type_info: type_info}} <-
           Contract.compile(source_code),
         {:ok, function_hash} <- :aeb_aevm_abi.type_hash_from_function_name(auth_fun, type_info),
         {:ok, calldata} <- Contract.create_calldata(source_code, @init_function, init_args),
         {:ok, source_hash} <- Hash.hash(source_code),
         byte_code_fields = [
           source_hash,
           type_info,
           byte_code
         ],
         serialized_wrapped_code = Serialization.serialize(byte_code_fields, :sophia_byte_code),
         ga_attach_tx = %{
           owner_id: public_key,
           nonce: nonce,
           code: serialized_wrapped_code,
           auth_fun: function_hash,
           ct_version: @ct_version,
           fee: Keyword.get(opts, :fee, 0),
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
           gas: Keyword.get(opts, :gas, Contract.default_gas()),
           gas_price: Keyword.get(opts, :gas_price, Contract.default_gas_price()),
           call_data: calldata
         },
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             client,
             ga_attach_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      {:ok, response}
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
     Computes an authorization id for given GA meta tx
  """
  @spec compute_auth_id(map()) :: {:ok, binary()}
  def compute_auth_id(%{ga_id: ga_id, auth_data: auth_data} = _meta_tx) do
    decoded_ga_id = Encoding.prefix_decode_base58c(ga_id)
    {:ok, _auth_id} = Hash.hash(decoded_ga_id <> auth_data)
  end

  @doc """
  false
  """
  def default_gas, do: @default_gas
end
