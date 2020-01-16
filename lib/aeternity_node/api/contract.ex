defmodule AeternityNode.Api.Contract do
  @moduledoc """
  API calls for all endpoints tagged `Contract`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get a contract by pubkey

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the contract
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.ContractObject{}} on success
  {:error, info} on failure
  """
  @spec get_contract(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.ContractObject.t()} | {:error, Tesla.Env.t()}
  def get_contract(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.ContractObject{}},
      {400, %AeternityNode.Model.Error{}},
      {404, false}
    ])
  end

  @doc """
  Get contract code by pubkey

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the contract
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.ByteCode{}} on success
  {:error, info} on failure
  """
  @spec get_contract_code(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.ByteCode.t()} | {:error, Tesla.Env.t()}
  def get_contract_code(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}/code")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.ByteCode{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a proof of inclusion for a contract

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): Contract pubkey to get proof for
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.PoI{}} on success
  {:error, info} on failure
  """
  @spec get_contract_po_i(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.PoI.t()} | {:error, Tesla.Env.t()}
  def get_contract_po_i(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}/poi")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.PoI{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get contract store by pubkey

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the contract
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.ContractStore{}} on success
  {:error, info} on failure
  """
  @spec get_contract_store(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.ContractStore.t()} | {:error, Tesla.Env.t()}
  def get_contract_store(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/#{pubkey}/store")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.ContractStore{}},
      {400, %AeternityNode.Model.Error{}},
      {404, false}
    ])
  end

  @doc """
  Get a contract_call transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCallTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_contract_call(Tesla.Env.client(), AeternityNode.Model.ContractCallTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_contract_call(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/call")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a contract_create transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCreateTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.CreateContractUnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_contract_create(
          Tesla.Env.client(),
          AeternityNode.Model.ContractCreateTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.CreateContractUnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_contract_create(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/create")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.CreateContractUnsignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end
end
