defmodule AeternityNode.Api.Contract do
  @moduledoc """
  API calls for all endpoints tagged `Contract`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Call a sophia function with a given name and argument in the given bytecode off chain.

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCallInput): contract call
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec call_contract(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def call_contract(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/code/call")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Compile a sophia contract from source and return byte code

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (Contract): contract code
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec compile_contract(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def compile_contract(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/code/compile")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Decode Sophia return data encoded according to Sophia ABI.

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (SophiaBinaryData): Binary data in Sophia ABI format
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec decode_data(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def decode_data(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/code/decode-data")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Encode sophia data and function name according to sophia ABI.

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCallInput): Arguments in sophia
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec encode_calldata(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def encode_calldata(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/code/encode-calldata")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a contract by pubkey

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the contract
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_contract(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_contract(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get contract code by pubkey

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the contract
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_contract_code(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_contract_code(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}/code")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a proof of inclusion for a contract

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): Contract pubkey to get proof for
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_contract_po_i(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_contract_po_i(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}/poi")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get contract store by pubkey

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the contract
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_contract_store(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_contract_store(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}/store")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a contract_call transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCallTx): 
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec post_contract_call(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def post_contract_call(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/call")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Compute the call_data for SOPHIA and get contract_call transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCallCompute): 
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec post_contract_call_compute(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def post_contract_call_compute(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/call/compute")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a contract_create transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCreateTx): 
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec post_contract_create(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def post_contract_create(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/create")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Compute the call_data for SOPHIA and get a contract_create transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCreateCompute): 
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec post_contract_create_compute(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def post_contract_create_compute(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/create/compute")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end
end
