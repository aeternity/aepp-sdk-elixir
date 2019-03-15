defmodule AeternityNode.Api.Chain do
  @moduledoc """
  API calls for all endpoints tagged `Chain`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get the current generation

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_current_generation(Tesla.Env.client(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_current_generation(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/generations/current")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get the current key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_current_key_block(Tesla.Env.client(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_current_key_block(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/current")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get the hash of the current key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_current_key_block_hash(Tesla.Env.client(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_current_key_block_hash(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/current/hash")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get the height of the current key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_current_key_block_height(Tesla.Env.client(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_current_key_block_height(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/current/height")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a generation by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the generation
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_generation_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_generation_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/generations/hash/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a generation by height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - height (integer()): The height of the generation
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_generation_by_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_generation_by_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/generations/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a key block by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_key_block_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_key_block_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/hash/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a key block by height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - height (integer()): The height of the block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_key_block_by_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_key_block_by_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a micro block header by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_micro_block_header_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_micro_block_header_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/header")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get a micro block transaction by hash and index

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - index (integer()): The index of the transaction in a block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_micro_block_transaction_by_hash_and_index(
          Tesla.Env.client(),
          String.t(),
          integer(),
          keyword()
        ) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_micro_block_transaction_by_hash_and_index(connection, hash, index, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/transactions/index/#{index}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get micro block transactions by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_micro_block_transactions_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_micro_block_transactions_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/transactions")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get micro block transaction count by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_micro_block_transactions_count_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_micro_block_transactions_count_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/transactions/count")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get the pending key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_pending_key_block(Tesla.Env.client(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_pending_key_block(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/pending")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Get the top block (either key or micro block)

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_top_block(Tesla.Env.client(), keyword()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_top_block(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/blocks/top")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end

  @doc """
  Post a mined key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (KeyBlock): Mined key block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec post_key_block(Tesla.Env.client(), map(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def post_key_block(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/key-blocks")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> decode()
  end
end
