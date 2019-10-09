defmodule AeppSDK.Contract do
  @moduledoc """
  Contains all contract-related functionality.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """

  alias AeppSDK.Client
  alias AeppSDK.Utils.Account, as: AccountUtils
  alias AeppSDK.Utils.Chain, as: ChainUtils
  alias AeppSDK.Utils.{Encoding, Keys, Serialization, Transaction}
  alias AeppSDK.Utils.Hash
  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Api.Debug, as: DebugApi

  alias AeternityNode.Model.{
    Account,
    ContractCallObject,
    ContractCallTx,
    ContractCreateTx,
    DryRunAccount,
    DryRunInput,
    DryRunResult,
    DryRunResults,
    Error
  }

  alias Tesla.Env

  @default_deposit 0
  @default_amount 0
  @default_gas 1_000_000
  @default_gas_price 1_000_000_000
  @init_function "init"
  @abi_version 0x01
  @genesis_beneficiary "ak_11111111111111111111111111111111273Yts"

  @type deploy_options :: [
          deposit: non_neg_integer(),
          amount: non_neg_integer(),
          gas: non_neg_integer(),
          gas_price: non_neg_integer(),
          fee: non_neg_integer(),
          ttl: non_neg_integer()
        ]

  @type call_options :: [
          fee: non_neg_integer(),
          ttl: non_neg_integer(),
          amount: non_neg_integer(),
          gas: non_neg_integer(),
          gas_price: non_neg_integer()
        ]

  @doc """
  Deploy a contract

  ## Example
      iex> source_code = "contract Number =
        record state = { number : int }

        entrypoint init(x : int) =
          { number = x }

        entrypoint add_to_number(x : int) =
          state.number + x"
      iex> init_args = ["42"]
      iex> AeppSDK.Contract.deploy(client, source_code, init_args)
      {:ok,
       %{
         block_hash: "mh_6fEZ9CCPNXxyjpKwSjkihv2UA5voRKCBpvrK24gK38zkZZB5Q",
         block_height: 86362,
         contract_id: "ct_2XphkkmsJAbR4NbSpYFgHPgzfpveKRA9FFTJmp6jX8JRqnveeD",
         log: [],
         return_type: "ok",
         return_value: "cb_Xfbg4g==",
         tx_hash: "th_CGCF321Sz8zWPMpSpa28gk3jDvvzeda8edhNhmnLgUvFYi14U"
       }}
  """
  @spec deploy(
          Client.t(),
          String.t(),
          list(String.t()),
          deploy_options()
        ) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c(),
             contract_id: Encoding.base58c(),
             log:
               list(%{
                 address: Encoding.base58c(),
                 data: String.t(),
                 topics: list(non_neg_integer())
               })
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def deploy(
        %Client{
          keypair: %{public: public_key},
          connection: connection
        } = client,
        source_code,
        init_args,
        opts \\ []
      )
      when is_binary(source_code) and is_list(init_args) and is_list(opts) do
    public_key_binary = Keys.public_key_to_binary(public_key)
    {:ok, source_hash} = Hash.hash(source_code)
    user_fee = Keyword.get(opts, :fee, 0)

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, public_key),
         {:ok, %{byte_code: byte_code, type_info: type_info}} <- compile(source_code),
         {:ok, calldata} <- create_calldata(source_code, @init_function, init_args),
         byte_code_fields <- [
           source_hash,
           type_info,
           byte_code
         ],
         serialized_wrapped_code <- Serialization.serialize(byte_code_fields, :sophia_byte_code),
         contract_create_tx <- %ContractCreateTx{
           owner_id: public_key,
           nonce: nonce,
           code: serialized_wrapped_code,
           abi_version: :unused,
           deposit: Keyword.get(opts, :deposit, @default_deposit),
           amount: Keyword.get(opts, :amount, @default_amount),
           gas: Keyword.get(opts, :gas, @default_gas),
           gas_price: Keyword.get(opts, :gas_price, @default_gas_price),
           fee: Keyword.get(opts, :fee, 0),
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
           call_data: calldata
         },
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             client,
             contract_create_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      contract_account = compute_contract_account(public_key_binary, nonce)

      {:ok,
       Map.merge(response, %{contract_id: contract_account, log: encode_logs(response.log, [])})}
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Call a contract

  ## Example
      iex> contract_address = "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"
      iex> source_code = "contract Identity =
        datatype event = AddedNumberEvent(indexed int, string)

        record state = { number : int }

        entrypoint init(x : int) =
          { number = x }

        stateful entrypoint add_to_number(x : int) =
          Chain.event(AddedNumberEvent(x, \"Added a number\"))
          state.number + x"
      iex> function_name = "add_to_number"
      iex> function_args = ["33"]
      iex> AeppSDK.Contract.call(client, contract_address, source_code, function_name, function_args)
      {:ok,
       %{
         block_hash: "mh_2uzSrRdURXy4ATwCo3XpeSngH9ECXhkBj3MWEYFatqK4pJgFWG",
         block_height: 86362,
         log: [
           %{
             address: "ct_2XphkkmsJAbR4NbSpYFgHPgzfpveKRA9FFTJmp6jX8JRqnveeD",
             data: "Added a number",
             topics: [100006271334006235721916574864225776454052674644157840164656436983196903186403,
              33]
           }
         ],
         return_type: "ok",
         return_value: 75,
         tx_hash: "th_CpexcQGiM86HVtHR6HTzYc3HoakXW2Xjm77wVKctoZmxTH52u"
       }}
  """
  @spec call(Client.t(), String.t(), String.t(), String.t(), list(String.t()), call_options()) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c(),
             return_value: String.t(),
             return_type: String.t(),
             log:
               list(%{
                 address: Encoding.base58c(),
                 data: String.t(),
                 topics: list(non_neg_integer())
               })
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def call(
        client,
        contract_address,
        source_code,
        function_name,
        function_args,
        opts \\ []
      ) do
    case :aeso_aci.contract_interface(:json, source_code) do
      {:ok, [%{contract: %{functions: functions}}]} ->
        case Enum.find(functions, fn %{name: name} -> name == function_name end) do
          %{stateful: is_stateful} ->
            case is_stateful do
              true ->
                call_on_chain(
                  client,
                  contract_address,
                  source_code,
                  function_name,
                  function_args,
                  opts
                )

              false ->
                call_static(
                  client,
                  contract_address,
                  source_code,
                  function_name,
                  function_args,
                  opts
                )
            end

          nil ->
            {:error, "Undefined function #{function_name}"}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Decode a return value

  ## Example
      iex> sophia_type = "int"
      iex> return_value = "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
      iex> return_type = "ok"
      iex> AeppSDK.Contract.decode_return_value(sophia_type, return_value, return_type)
      {:ok, 75}
  """
  @spec decode_return_value(String.t(), String.t(), String.t()) ::
          {:ok, tuple()} | {:error, atom()}
  def decode_return_value(
        sophia_type,
        return_value,
        return_type
      )
      when is_binary(sophia_type) and is_binary(return_value) and is_binary(return_type) do
    sophia_type_charlist = String.to_charlist(sophia_type)

    with "ok" <- return_type,
         {:ok, decoded_return_value} <-
           :aeser_api_encoder.safe_decode(:contract_bytearray, return_value),
         {:ok, typerep} <- :aeso_compiler.sophia_type_to_typerep(sophia_type_charlist) do
      :aeb_heap.from_binary(typerep, decoded_return_value)
    else
      {:error, _} = error ->
        error

      _ ->
        {:ok, decoded_return_value} =
          :aeser_api_encoder.safe_decode(:contract_bytearray, return_value)

        {:ok, message} = :aeb_heap.from_binary(:string, decoded_return_value)
        {:error, message}
    end
  end

  @doc """
  Compile a contract

  ## Example
      iex> source_code = "contract Number =
        record state = { number : int }

        entrypoint init(x : int) =
          { number = x }

        entrypoint add_to_number(x : int) =
          state.number + x"
      iex> AeppSDK.Contract.compile(source_code)
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
         compiler_version: "3.0.0",
         contract_source: 'contract Number =
           record state = { number : int }

           entrypoint init(x : int) =
             { number = x }

           entrypoint add_to_number(x : int) =
             state.number + x',
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

  ## Example
      iex> source_code = "contract Number =
        record state = { number : int }

        entrypoint init(x : int) =
          { number = x }

        entrypoint add_to_number(x : int) =
          state.number + x"
      iex> function_name = "init"
      iex> function_args = ["42"]
      iex> AeppSDK.Contract.create_calldata(source_code, function_name, function_args)
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
      {:ok, calldata} =
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

  @doc """
  Get the return type of a function in a contract

  ## Example
      iex> source_code = "contract Identity =
        record state = { number : int }

        entrypoint init(x : int) =
          { number = x }

        entrypoint add_to_number(x : int) =
          state.number + x"
      iex> function_name = "add_to_number"
      iex> AeppSDK.Contract.get_function_return_type(source_code, function_name)
      {:ok, "int"}
  """
  @spec get_function_return_type(String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_function_return_type(source_code, function_name) do
    case :aeso_aci.contract_interface(:json, source_code) do
      {:ok, [%{contract: %{functions: functions}}]} ->
        case Enum.find(functions, fn %{name: name} -> name == function_name end) do
          %{returns: function_return_type} ->
            case aci_to_sophia_type(function_return_type) do
              {:error, _} = err ->
                err

              type ->
                {:ok, type}
            end

          nil ->
            {:error, "Undefined function #{function_name}"}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  false
  """
  def abi_version, do: @abi_version

  @doc """
  false
  """
  def default_amount, do: @default_amount

  @doc """
  false
  """
  def default_deposit, do: @default_deposit

  @doc """
  false
  """
  def default_gas, do: @default_gas

  @doc """
  false
  """
  def default_gas_price, do: @default_gas_price

  @doc """
  false
  """
  def encode_logs(logs, topic_types) do
    Enum.map(logs, fn log ->
      string_data = Encoding.prefix_decode_base64(log.data)

      log
      |> Map.from_struct()
      |> Map.replace!(:data, string_data)
      |> Map.update!(:topics, fn [event_name | rest_topics] = topics ->
        case topic_types do
          [] ->
            topics

          _ ->
            {encoded_topics, _} =
              Enum.reduce(rest_topics, {[], topic_types}, fn topic,
                                                             {encoded_topics,
                                                              [topic_type | rest_types]} ->
                {[encode_topic(topic_type, topic) | encoded_topics], rest_types}
              end)

            [event_name | Enum.reverse(encoded_topics)]
        end
      end)
    end)
  end

  def call_on_chain(
        %Client{
          connection: connection
        } = client,
        contract_address,
        source_code,
        function_name,
        function_args,
        opts
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
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             client,
             contract_call_tx,
             Keyword.get(opts, :auth, nil),
             height
           ),
         {:ok, function_return_type} <- get_function_return_type(source_code, function_name),
         {:ok, decoded_return_value} <-
           decode_return_value(function_return_type, response.return_value, response.return_type) do
      {:ok, %{response | return_value: decoded_return_value, log: encode_logs(response.log, [])}}
    else
      {:error, _} = error ->
        error
    end
  end

  defp call_static(
         %Client{
           connection: connection,
           internal_connection: internal_connection
         } = client,
         contract_address,
         source_code,
         function_name,
         function_args,
         opts
       )
       when is_binary(contract_address) and is_binary(source_code) and is_binary(function_name) and
              is_list(function_args) and is_list(opts) do
    with {:ok, top_block_hash} <- ChainUtils.get_top_block_hash(connection),
         {caller_public_key, caller_balance} <-
           determine_caller(client, Keyword.get(opts, :top, top_block_hash), opts),
         {:ok, contract_call_tx} <-
           build_contract_call_tx(
             %Client{client | keypair: %{public: caller_public_key}},
             contract_address,
             source_code,
             function_name,
             function_args,
             opts
           ),
         serialized_contract_call_tx = Serialization.serialize(contract_call_tx),
         encoded_contract_call_tx =
           Encoding.prefix_encode_base64("tx", serialized_contract_call_tx),
         {:ok,
          %DryRunResults{
            results: [
              %DryRunResult{
                call_obj: %ContractCallObject{
                  return_type: return_type,
                  return_value: return_value,
                  log: log
                }
              }
            ]
          }} <-
           DebugApi.dry_run_txs(internal_connection, %DryRunInput{
             top: Keyword.get(opts, :top, top_block_hash),
             accounts: [%DryRunAccount{pub_key: caller_public_key, amount: caller_balance}],
             txs: [encoded_contract_call_tx]
           }),
         {:ok, function_return_type} <- get_function_return_type(source_code, function_name),
         {:ok, decoded_return_value} <-
           decode_return_value(function_return_type, return_value, return_type) do
      {:ok,
       %{return_value: decoded_return_value, return_type: return_type, log: encode_logs(log, [])}}
    else
      {:ok,
       %DryRunResults{
         results: [
           %DryRunResult{call_obj: nil, reason: message, result: "error", type: "contract_call"}
         ]
       }} ->
        {:error, message}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  defp encode_topic(:address, topic), do: encode_hash(topic, "ak")

  defp encode_topic(:contract, topic), do: encode_hash(topic, "ct")

  defp encode_topic(:oracle, topic), do: encode_hash(topic, "ok")

  defp encode_topic(:oracle_query, topic), do: encode_hash(topic, "oq")

  defp encode_topic(:int, topic), do: topic

  defp encode_topic(:bits, topic), do: topic

  defp encode_topic(:bytes, topic), do: topic

  defp encode_topic(:bool, topic) do
    case topic do
      1 ->
        true

      0 ->
        false
    end
  end

  defp encode_hash(hash, prefix) do
    binary_hash = :binary.encode_unsigned(hash)
    Encoding.prefix_encode_base58c(prefix, binary_hash)
  end

  defp type_to_string(type) do
    if is_atom(type) do
      Atom.to_string(type)
    else
      type
    end
  end

  defp aci_to_sophia_type(type) do
    case type do
      %{} ->
        structure_type = type |> Map.keys() |> List.first() |> type_to_string()
        field_types = type |> Map.values() |> List.first() |> type_to_string()
        aci_to_sophia_type(structure_type, field_types)

      [type] ->
        type |> type_to_string() |> aci_to_sophia_type()

      type ->
        type
    end
  end

  defp aci_to_sophia_type("tuple", fields) do
    fields
    |> Enum.map(fn field ->
      aci_to_sophia_type(field)
    end)
    |> into_tuple()
  end

  defp aci_to_sophia_type("record", fields) do
    fields
    |> Enum.map(fn field ->
      aci_to_sophia_type(field["type"])
    end)
    |> into_tuple()
  end

  defp aci_to_sophia_type("map", [key_type, value_type]),
    do: "map(#{aci_to_sophia_type(key_type)}, #{aci_to_sophia_type(value_type)})"

  defp aci_to_sophia_type("list", type), do: "list(#{aci_to_sophia_type(type)})"

  defp aci_to_sophia_type("oracle", [query_type, response_type]),
    do: "oracle(#{aci_to_sophia_type(query_type)},#{aci_to_sophia_type(response_type)})"

  defp aci_to_sophia_type("oracle_query", [query_type, response_type]),
    do: "oracle_query(#{aci_to_sophia_type(query_type)},#{aci_to_sophia_type(response_type)})"

  defp aci_to_sophia_type(type, _), do: {:error, "Can't decode type: #{type}"}

  defp into_tuple(fields), do: "(#{Enum.join(fields, ", ")})"

  defp compute_contract_account(owner_address, nonce) do
    nonce_binary = :binary.encode_unsigned(nonce)
    {:ok, hash} = Hash.hash(<<owner_address::binary, nonce_binary::binary>>)

    Encoding.prefix_encode_base58c("ct", hash)
  end

  defp build_contract_call_tx(
         %Client{
           keypair: %{public: public_key},
           connection: connection
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

        AccountUtils.nonce_at_hash(connection, public_key, top_block_hash)
      else
        AccountUtils.next_valid_nonce(connection, public_key)
      end

    with {:ok, nonce} <- nonce_result,
         {:ok, calldata} <- create_calldata(source_code, function_name, function_args) do
      contract_call_tx = %ContractCallTx{
        caller_id: public_key,
        nonce: nonce,
        contract_id: contract_address,
        abi_version: @abi_version,
        fee: Keyword.get(opts, :fee, 0),
        ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
        amount: Keyword.get(opts, :amount, @default_amount),
        gas: Keyword.get(opts, :gas, @default_gas),
        gas_price: Keyword.get(opts, :gas_price, @default_gas_price),
        call_data: calldata
      }

      {:ok, contract_call_tx}
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}

      {:error, _} = error ->
        error
    end
  end

  defp determine_caller(
         %Client{keypair: %{public: public_key}, connection: connection},
         block_hash,
         opts
       ) do
    min_balance =
      Keyword.get(opts, :gas, @default_gas) * Keyword.get(opts, :gas_price, @default_gas_price) +
        Keyword.get(opts, :fee, 0)

    with {:ok, %Account{balance: balance}} <-
           AccountApi.get_account_by_pubkey_and_hash(
             connection,
             public_key,
             block_hash
           ),
         true <- balance >= min_balance do
      {public_key, balance}
    else
      false ->
        {public_key, min_balance}

      _ ->
        {@genesis_beneficiary, min_balance}
    end
  end
end
