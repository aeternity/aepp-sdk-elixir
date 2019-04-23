defmodule Core.Contract do
  alias AeternityNode.Api.Debug, as: DebugApi
  alias AeternityNode.Api.Chain, as: ChainApi

  alias AeternityNode.Model.{
    ContractCallObject,
    GenericSignedTx,
    ContractCallTx,
    ContractCreateTx,
    DryRunInput,
    DryRunResult,
    DryRunResults,
    Error
  }

  alias AeternityNode.Model.InlineResponse2001, as: HeightResponse

  alias Utils.{Serialization, Encoding, Keys}
  alias Utils.Account, as: AccountUtils
  alias Utils.Chain, as: ChainUtils
  alias Utils.Transaction, as: TransactionUtils
  alias Core.Client
  alias Tesla.Env

  @default_deposit 0
  @default_amount 0
  @default_gas 1_000_000
  @default_gas_price 1_000_000_000
  @init_function "init"
  @abi_version 0x01
  @hash_bytes 32

  @doc """
  Deploy a contract

  ## Examples
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> url = "https://sdk-testnet.aepps.com/v2"
      iex> internal_url = "https://sdk-testnet.aepps.com/v2"
      iex> client = Core.Client.new(%{pubkey: pubkey, privkey: privkey}, network_id, url, internal_url)
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> init_args = ["42"]
      iex> Core.Contract.deploy(client, source_code, init_args)
      {:ok, "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"}
  """
  @spec deploy(Client.t(), String.t(), list(String.t()), list()) ::
          {:ok, String.t()} | {:error, String.t()} | {:error, Env.t()}
  def deploy(
        %Client{
          keypair: %{public: pubkey, secret: privkey},
          network_id: network_id,
          connection: connection
        },
        source_code,
        init_args,
        opts \\ []
      )
      when is_binary(source_code) and is_list(init_args) and is_list(opts) do
    pubkey_binary = Keys.pubkey_to_binary(pubkey)
    {:ok, source_hash} = hash(source_code)

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         {:ok, %{byte_code: byte_code, type_info: type_info}} <- compile(source_code),
         {:ok, calldata} <- create_calldata(source_code, @init_function, init_args),
         byte_code_fields = [
           source_hash,
           type_info,
           byte_code
         ],
         serialized_wrapped_code = Serialization.serialize(byte_code_fields, :sophia_byte_code),
         tx_dummy_fee = %ContractCreateTx{
           owner_id: pubkey,
           nonce: nonce,
           code: serialized_wrapped_code,
           vm_version: :unused,
           abi_version: :unused,
           deposit: Keyword.get(opts, :deposit, @default_deposit),
           amount: Keyword.get(opts, :amount, @default_amount),
           gas: Keyword.get(opts, :gas, @default_gas),
           gas_price: Keyword.get(opts, :gas_price, @default_gas_price),
           fee: 0,
           ttl: Keyword.get(opts, :ttl, TransactionUtils.default_ttl()),
           call_data: calldata
         },
         {:ok, %HeightResponse{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         tx = %{
           tx_dummy_fee
           | fee:
               Keyword.get(
                 opts,
                 :fee,
                 TransactionUtils.calculate_min_fee(tx_dummy_fee, height, network_id)
               )
         },
         {:ok, %GenericSignedTx{}} <-
           TransactionUtils.post(
             connection,
             privkey,
             network_id,
             tx
           ),
         contract_pubkey = compute_contract_pubkey(pubkey_binary, nonce) do
      {:ok, contract_pubkey}
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Call a contract

  ## Examples
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> url = "https://sdk-testnet.aepps.com/v2"
      iex> internal_url = "https://sdk-testnet.aepps.com/v2"
      iex> client = Core.Client.new(%{public: pubkey, secret: privkey}, network_id, url, internal_url)
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> function_name = "add_to_number"
      iex> function_args = ["33"]
      iex> Core.Contract.call(client, contract_address, source_code, function_name, function_args)
      {:ok,
        %{
         return_type: "ok",
         return_value: "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
        }}
  """
  @spec call(Client.t(), String.t(), String.t(), String.t(), list(String.t()), list()) ::
          {:ok, %{return_value: String.t(), return_type: String.t()}}
          | {:error, String.t()}
          | {:error, Env.t()}
  def call(
        %Client{
          keypair: %{secret: privkey},
          network_id: network_id,
          connection: connection
        } = client,
        contract_address,
        source_code,
        function_name,
        function_args,
        opts \\ []
      )
      when is_binary(contract_address) and is_binary(source_code) and is_binary(function_name) and
             is_list(function_args) and is_list(opts) do
    with {:ok, contract_call_tx} <-
           build_contract_call_tx(
             client,
             contract_address,
             source_code,
             function_name,
             function_args,
             opts
           ),
         {:ok, %ContractCallObject{return_value: return_value, return_type: return_type}} <-
           TransactionUtils.post(
             connection,
             privkey,
             network_id,
             contract_call_tx
           ) do
      {:ok, %{return_value: return_value, return_type: return_type}}
    else
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Call a contract without posting a transaction (execute off-chain)

  ## Examples
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> url = "https://sdk-testnet.aepps.com/v2"
      iex> internal_url = "https://sdk-testnet.aepps.com/v2"
      iex> client = Core.Client.new(%{public: pubkey, secret: privkey}, network_id, url, internal_url)
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> function_name = "add_to_number"
      iex> function_args = ["33"]
      iex> top_block_hash = "kh_WPQzXtyDiwvUs54N1L88YsLPn51PERHF76bqcMhpT5vnrAEAT"
      iex> Core.Contract.call_static(client, contract_address, source_code, function_name, function_args, [top: top_block_hash])
      {:ok,
        %{
         return_type: "ok",
         return_value: "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
        }}
  """
  @spec call_static(Client.t(), String.t(), String.t(), String.t(), list(String.t()), list()) ::
          {:ok, %{return_value: String.t(), return_type: String.t()}}
          | {:error, String.t()}
          | {:error, Env.t()}
  def call_static(
        %Client{
          connection: connection,
          internal_connection: internal_connection
        } = client,
        contract_address,
        source_code,
        function_name,
        function_args,
        opts \\ []
      )
      when is_binary(contract_address) and is_binary(source_code) and is_binary(function_name) and
             is_list(function_args) and is_list(opts) do
    with {:ok, contract_call_tx} <-
           build_contract_call_tx(
             client,
             contract_address,
             source_code,
             function_name,
             function_args,
             opts
           ),
         serialized_contract_call_tx = Serialization.serialize(contract_call_tx),
         {:ok, top_block_hash} <- ChainUtils.get_top_block_hash(connection),
         encoded_contract_call_tx =
           Encoding.prefix_encode_base64("tx", serialized_contract_call_tx),
         {:ok,
          %DryRunResults{
            results: [
              %DryRunResult{
                call_obj: %ContractCallObject{
                  return_type: return_type,
                  return_value: return_value
                }
              }
            ]
          }} <-
           DebugApi.dry_run_txs(internal_connection, %DryRunInput{
             top: Keyword.get(opts, :top, top_block_hash),
             accounts: [],
             txs: [encoded_contract_call_tx]
           }) do
      {:ok, %{return_value: return_value, return_type: return_type}}
    else
      {:ok,
       %DryRunResults{
         results: [
           %DryRunResult{call_obj: nil, reason: message, result: "error", type: "contract_call"}
         ]
       }} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Decode a return value

  ## Examples
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> url = "https://sdk-testnet.aepps.com/v2"
      iex> internal_url = "https://sdk-testnet.aepps.com/v2"
      iex> client = Core.Client.new(%{public: pubkey, secret: privkey}, network_id, url, internal_url)
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> function_name = "add_to_number"
      iex> function_args = ["33"]
      iex> {:ok, %{return_value: data, return_type: "ok"}} = Core.Contract.call(client, contract_address, source_code, function_name, function_args)
        iex> data_type = "int"
      iex> Core.Contract.decode_return_value(data_type, data)
      {:ok, 75}
  """
  @spec decode_return_value(String.t(), String.t()) :: {:ok, tuple()} | {:error, atom()}
  def decode_return_value(
        sophia_type,
        return_value
      )
      when is_binary(sophia_type) and is_binary(return_value) do
    sophia_type_charlist = String.to_charlist(sophia_type)

    with {:ok, decoded_return_value} <-
           :aeser_api_encoder.safe_decode(:contract_bytearray, return_value),
         {:ok, typerep} <- :aeso_compiler.sophia_type_to_typerep(sophia_type_charlist) do
      :aeb_heap.from_binary(typerep, decoded_return_value)
    else
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Compile a contract

  ## Examples
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> Core.Contract.compile(source_code)
      {:ok,
       %{
         byte_code: <<98, 0, 0, 100, 98, 0, 0, 151, 145, 128, 128, 128, 81, 127, 112,
           194, 27, 63, 171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2, 111, 12,
           11, 11, 82, 86, 82, 53, 206, 145, 155, 60, 13, 206, 214, 183, 62, 20, 98,
           0, 0, 242, 87, 80, 128, 81, 127, 226, 35, 29, 108, 223, 201, 57, 22, 222,
           76, 179, 169, 133, 123, 246, 92, 244, 15, 194, 86, 244, 161, 73, 139, 63,
           126, 124, 152, 12, 25, 147, 68, 20, 98, 0, 0, 170, 87, 80, 96, 1, 25, 81,
           0, 91, 96, 0, 25, 89, 96, 32, 1, 144, 129, 82, 96, 32, 144, 3, 96, 0, 89,
           144, 129, 82, 129, 82, 89, 96, 32, 1, 144, 129, 82, 96, 32, 144, 3, 96, 3,
           129, 82, 144, 89, 96, 0, 81, 89, 82, 96, 0, 82, 96, 0, 243, 91, 96, 0, 128,
           82, 96, 0, 243, 91, 128, 96, 0, 81, 81, 1, 144, 80, 144, 86, 91, 96, 32, 1,
           81, 81, 131, 146, 80, 128, 145, 80, 80, 128, 89, 144, 129, 82, 89, 96, 32,
           1, 144, 129, 82, 96, 32, 144, 3, 96, 0, 25, 89, 96, 32, 1, 144, 129, 82,
           96, 32, 144, 3, 96, 0, 89, 144, 129, 82, 129, 82, 89, 96, 32, 1, 144, 129,
           82, 96, 32, 144, 3, 96, 3, 129, 82, 129, 82, 144, 80, 144, 86, 91, 96, 32,
           1, 81, 81, 144, 80, 89, 80, 128, 145, 80, 80, 98, 0, 0, 159, 86>>,
         compiler_version: "2.1.0",
         contract_source: 'contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x',
         type_info: [
           {<<112, 194, 27, 63, 171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2,
              111, 12, 11, 11, 82, 86, 82, 53, 206, 145, 155, 60, 13, 206, 214, 183,
              62>>, "add_to_number",
            <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 160, 255, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
            <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
           {<<226, 35, 29, 108, 223, 201, 57, 22, 222, 76, 179, 169, 133, 123, 246,
              92, 244, 15, 194, 86, 244, 161, 73, 139, 63, 126, 124, 152, 12, 25, 147,
              68>>, "init",
            <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 160, 255, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
            <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 192, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 1, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 128, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
              255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0>>}
         ]
       }}
  """
  @spec compile(String.t()) :: {:ok, map()} | {:error, String.t()}
  def compile(source_code) when is_binary(source_code) do
    charlist_source = String.to_charlist(source_code)

    try do
      :aeso_compiler.from_string(charlist_source, [])
    rescue
      e in ErlangError ->
        %ErlangError{original: {_, message}} = e

        {:error, message}
    end
  end

  @doc """
  Create contract calldata

  ## Examples
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> function_name = "init"
      iex> function_args = ["42"]
      iex> Core.Contract.create_calldata(source_code, function_name, function_args)
      {:ok,
         <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 32, 226, 35, 29, 108, 223, 201, 57, 22, 222, 76, 179, 169,
           133, 123, 246, 92, 244, 15, 194, 86, 244, 161, 73, 139, 63, 126, 124, 152,
           12, 25, 147, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42>>}
  """
  @spec create_calldata(String.t(), String.t(), list(String.t())) ::
          {:ok, binary()} | {:error, String.t()}
  def create_calldata(
        source_code,
        function_name,
        function_args
      )
      when is_binary(source_code) and is_binary(function_name) and is_list(function_args) do
    charlist_source_code = String.to_charlist(source_code)
    charlist_function_name = String.to_charlist(function_name)

    charlist_function_args =
      Enum.map(function_args, fn arg ->
        String.to_charlist(arg)
      end)

    try do
      {:ok, calldata, _, _} =
        :aeso_compiler.create_calldata(
          charlist_source_code,
          charlist_function_name,
          charlist_function_args
        )

      {:ok, calldata}
    rescue
      e in ErlangError ->
        message =
          case e do
            %ErlangError{original: {_, message}} ->
              message

            %MatchError{term: {:error, message}} ->
              message
          end

        {:error, message}
    end
  end

  defp compute_contract_pubkey(owner_address, nonce) do
    nonce_binary = :binary.encode_unsigned(nonce)
    {:ok, hash} = hash(<<owner_address::binary, nonce_binary::binary>>)

    Encoding.prefix_encode_base58c("ct", hash)
  end

  defp build_contract_call_tx(
         %Client{
           keypair: %{public: pubkey},
           connection: connection,
           network_id: network_id
         },
         contract_address,
         source_code,
         function_name,
         function_args,
         opts
       ) do
    nonce_result =
      if Keyword.has_key?(opts, :top) do
        top_block_hash = Keyword.get(opts, :top)
        AccountUtils.nonce_at_hash(connection, pubkey, top_block_hash)
      else
        AccountUtils.next_valid_nonce(connection, pubkey)
      end

    with {:ok, nonce} <- nonce_result,
         {:ok, calldata} <- create_calldata(source_code, function_name, function_args),
         tx_dummy_fee = %ContractCallTx{
           caller_id: pubkey,
           nonce: nonce,
           contract_id: contract_address,
           vm_version: :unused,
           abi_version: @abi_version,
           fee: 0,
           ttl: Keyword.get(opts, :ttl, TransactionUtils.default_ttl()),
           amount: Keyword.get(opts, :amount, @default_amount),
           gas: Keyword.get(opts, :gas, @default_gas),
           gas_price: Keyword.get(opts, :gas_price, @default_gas_price),
           call_data: calldata
         },
         {:ok, %HeightResponse{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         tx = %{
           tx_dummy_fee
           | fee:
               Keyword.get(
                 opts,
                 :fee,
                 TransactionUtils.calculate_min_fee(tx_dummy_fee, height, network_id)
               )
         } do
      {:ok, tx}
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}

      {:error, _} = error ->
        error
    end
  end

  defp hash(payload) do
    :enacl.generichash(@hash_bytes, payload)
  end
end
