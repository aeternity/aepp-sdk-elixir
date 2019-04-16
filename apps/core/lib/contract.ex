defmodule Core.Contract do
  alias AeternityNode.Api.Contract, as: ContractApi
  alias AeternityNode.Api.Debug, as: DebugApi

  alias AeternityNode.Model.{
    ByteCode,
    ContractCallObject,
    DryRunInput,
    DryRunResult,
    DryRunResults,
    Error
  }

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
  @init_function 'init'
  # vm_version 0x03 and abi_version 0x01, packed together
  @ct_version 0x30001
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
      iex> init_args = "42"
      iex> Core.Contract.deploy(client, source_code, init_args)
      {:ok, "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"}
  """

  @spec deploy(Client.t(), String.t(), String.t(), list()) ::
          {:ok, String.t()} | {:error, String.t()} | {:error, Env.t()}

  def deploy(
        %Client{
          keypair: %{pubkey: pubkey, privkey: privkey},
          network_id: network_id,
          connection: connection
        },
        source_code,
        init_args,
        opts \\ []
      )
      when is_binary(source_code) and is_list(opts) do
    pubkey_binary = Keys.pubkey_to_binary(pubkey)
    owner_id = Serialization.id_to_record(pubkey_binary, :account)
    source_code_charlist = String.to_charlist(source_code)
    init_args_charlist = String.to_charlist(init_args)
    {:ok, source_hash} = hash(source_code)

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         {:ok, %{byte_code: byte_code, type_info: type_info} = contract} <-
           compile(source_code_charlist),
         {:ok, calldata} <- create_calldata(contract, @init_function, init_args_charlist),
         byte_code_fields = [
           source_hash,
           type_info,
           byte_code
         ],
         serialized_wrapped_code = Serialization.serialize(byte_code_fields, :sophia_byte_code),
         contract_create_fields = [
           owner_id,
           nonce,
           serialized_wrapped_code,
           @ct_version,
           Keyword.get(opts, :fee, TransactionUtils.calculate_min_fee()),
           Keyword.get(opts, :ttl, TransactionUtils.default_ttl()),
           Keyword.get(opts, :deposit, @default_deposit),
           Keyword.get(opts, :amount, @default_amount),
           Keyword.get(opts, :gas, @default_gas),
           Keyword.get(opts, :gas_price, @default_gas_price),
           calldata
         ],
         {:ok, %ContractCallObject{}} <-
           TransactionUtils.post(
             connection,
             privkey,
             network_id,
             contract_create_fields,
             :contract_create_tx
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
      iex> client = Core.Client.new(%{pubkey: pubkey, privkey: privkey}, network_id, url, internal_url)
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> function_name = "add_to_number"
      iex> function_args = "33"
      iex> Core.Contract.call(client, contract_address, function_name, function_args)
      {:ok,
        %{
         return_type: "ok",
         return_value: "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
        }}
  """

  @spec call(Client.t(), String.t(), String.t(), String.t(), list()) ::
          {:ok, %{return_value: String.t(), return_type: String.t()}}
          | {:error, String.t()}
          | {:error, Env.t()}
  def call(
        %Client{
          keypair: %{privkey: privkey},
          network_id: network_id,
          connection: connection
        } = client,
        contract_address,
        function_name,
        function_args,
        opts \\ []
      )
      when is_binary(contract_address) and is_binary(function_name) and is_list(opts) do
    function_name_charlist = String.to_charlist(function_name)
    function_args_charlist = String.to_charlist(function_args)

    with {:ok, contract_call_fields} <-
           build_contract_call_fields(
             client,
             contract_address,
             function_name_charlist,
             function_args_charlist,
             opts
           ),
         {:ok, %ContractCallObject{return_value: return_value, return_type: return_type}} <-
           TransactionUtils.post(
             connection,
             privkey,
             network_id,
             contract_call_fields,
             :contract_call_tx
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
      iex> client = Core.Client.new(%{pubkey: pubkey, privkey: privkey}, network_id, url, internal_url)
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> function_name = "add_to_number"
      iex> function_args = "33"
      iex> top_block_hash = "kh_WPQzXtyDiwvUs54N1L88YsLPn51PERHF76bqcMhpT5vnrAEAT"
      iex> Core.Contract.call_static(client, contract_address, function_name, function_args, [top: top_block_hash])
      {:ok,
        %{
         return_type: "ok",
         return_value: "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
        }}
  """

  @spec call_static(Client.t(), String.t(), String.t(), String.t(), list()) ::
          {:ok, %{return_value: String.t(), return_type: String.t()}}
          | {:error, String.t()}
          | {:error, Env.t()}
  def call_static(
        %Client{
          connection: connection,
          internal_connection: internal_connection
        } = client,
        contract_address,
        function_name,
        function_args,
        opts \\ []
      )
      when is_binary(contract_address) and is_binary(function_name) and is_list(opts) do
    function_name_charlist = String.to_charlist(function_name)
    function_args_charlist = String.to_charlist(function_args)

    with {:ok, contract_call_fields} <-
           build_contract_call_fields(
             client,
             contract_address,
             function_name_charlist,
             function_args_charlist,
             opts
           ),
         serialized_contract_call_fields =
           Serialization.serialize(contract_call_fields, :contract_call_tx),
         {:ok, top_block_hash} <- ChainUtils.get_top_block_hash(connection),
         encoded_contract_call_tx =
           Encoding.prefix_encode_base64("tx", serialized_contract_call_fields),
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
      iex> client = Core.Client.new(%{pubkey: pubkey, privkey: privkey}, network_id, url, internal_url)
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> function_name = "add_to_number"
      iex> function_args = "33"
      iex> {:ok, %{return_value: data, return_type: "ok"}} = Core.Contract.call(client, contract_address, function_name, function_args)
      iex> data_type = "int"
      iex> Core.Contract.decode_return_value(data_type, data)
      {:ok, 75}
  """

  @spec decode_return_value(String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def decode_return_value(
        sophia_type,
        return_value
      )
      when is_binary(sophia_type) and is_binary(return_value) do
    sophia_type_charlist = String.to_charlist(sophia_type)

    with {:ok, decoded_return_value} <-
           :aeser_api_encoder.safe_decode(:contract_bytearray, return_value),
         {:ok, typerep} <- :aeso_compiler.sophia_type_to_typerep(sophia_type_charlist) do
      :aeso_heap.from_binary(typerep, decoded_return_value)
    else
      {:error, _} = error ->
        error
    end
  end

  defp compute_contract_pubkey(owner_address, nonce) do
    nonce_binary = :binary.encode_unsigned(nonce)
    {:ok, hash} = hash(<<owner_address::binary, nonce_binary::binary>>)

    Encoding.prefix_encode_base58c("ct", hash)
  end

  defp build_contract_call_fields(
         %Client{
           keypair: %{pubkey: pubkey},
           connection: connection
         },
         contract_address,
         function_name,
         function_args,
         opts
       ) do
    owner_id = pubkey |> Keys.pubkey_to_binary() |> Serialization.id_to_record(:account)

    contract_id =
      contract_address
      |> Encoding.prefix_decode_base58c()
      |> Serialization.id_to_record(:contract)

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         {:ok, %ByteCode{bytecode: bytecode}} <-
           ContractApi.get_contract_code(connection, contract_address),
         decoded_bytecode = Encoding.prefix_decode_base64(bytecode),
         [_, type_info: type_info, byte_code: byte_code] =
           Serialization.deserialize(decoded_bytecode, :sophia_byte_code),
         contract = %{
           type_info: type_info,
           byte_code: byte_code
         },
         {:ok, calldata} <- create_calldata(contract, function_name, function_args) do
      contract_call_fields = [
        owner_id,
        nonce,
        contract_id,
        @abi_version,
        Keyword.get(opts, :fee, TransactionUtils.calculate_min_fee()),
        Keyword.get(opts, :ttl, TransactionUtils.default_ttl()),
        Keyword.get(opts, :amount, @default_amount),
        Keyword.get(opts, :gas, @default_gas),
        Keyword.get(opts, :gas_price, @default_gas_price),
        calldata
      ]

      {:ok, contract_call_fields}
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

  defp compile(source_code) do
    try do
      contract = :aeso_compiler.from_string(source_code, [])

      {:ok, contract}
    rescue
      e in ErlangError ->
        %ErlangError{original: {_, message_list}} = e

        {:error, message_list}
    end
  end

  defp create_calldata(
         contract,
         function_name,
         function_args
       ) do
    try do
      {:ok, calldata, _, _} =
        :aeso_compiler.create_calldata(
          contract,
          function_name,
          function_args
        )

      {:ok, calldata}
    rescue
      e in ErlangError ->
        message =
          case e do
            %ErlangError{original: {_, message_list}} ->
              message_list

            %MatchError{term: {:error, message}} ->
              message
          end

        {:error, message}
    end
  end
end
