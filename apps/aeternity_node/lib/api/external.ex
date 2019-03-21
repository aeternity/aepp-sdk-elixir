defmodule AeternityNode.Api.External do
  @moduledoc """
  API calls for all endpoints tagged `External`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get an account by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Account{}} on success
  {:error, info} on failure
  """
  @spec get_account_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.Account.t()} | {:error, Tesla.Env.t()}
  def get_account_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Account{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get an account by public key after the block indicated by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Account{}} on success
  {:error, info} on failure
  """
  @spec get_account_by_pubkey_and_hash(Tesla.Env.client(), String.t(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.Account.t()} | {:error, Tesla.Env.t()}
  def get_account_by_pubkey_and_hash(connection, pubkey, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}/hash/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Account{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get an account by public key after the opening key block of the generation at height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - height (integer()): The height of the key block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Account{}} on success
  {:error, info} on failure
  """
  @spec get_account_by_pubkey_and_height(Tesla.Env.client(), String.t(), integer(), keyword()) ::
          {:ok, AeternityNode.Model.Account.t()} | {:error, Tesla.Env.t()}
  def get_account_by_pubkey_and_height(connection, pubkey, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Account{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get channel by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the channel
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Channel{}} on success
  {:error, info} on failure
  """
  @spec get_channel_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.Channel.t()} | {:error, Tesla.Env.t()}
  def get_channel_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/channels/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Channel{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

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
  Get the current generation

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Generation{}} on success
  {:error, info} on failure
  """
  @spec get_current_generation(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.Generation.t()} | {:error, Tesla.Env.t()}
  def get_current_generation(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/generations/current")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Generation{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get the current key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.KeyBlock{}} on success
  {:error, info} on failure
  """
  @spec get_current_key_block(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.KeyBlock.t()} | {:error, Tesla.Env.t()}
  def get_current_key_block(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/current")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.KeyBlock{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get the hash of the current key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.InlineResponse200{}} on success
  {:error, info} on failure
  """
  @spec get_current_key_block_hash(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.InlineResponse200.t()} | {:error, Tesla.Env.t()}
  def get_current_key_block_hash(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/current/hash")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.InlineResponse200{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get the height of the current key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.InlineResponse2001{}} on success
  {:error, info} on failure
  """
  @spec get_current_key_block_height(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.InlineResponse2001.t()} | {:error, Tesla.Env.t()}
  def get_current_key_block_height(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/current/height")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.InlineResponse2001{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a generation by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the generation
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Generation{}} on success
  {:error, info} on failure
  """
  @spec get_generation_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.Generation.t()} | {:error, Tesla.Env.t()}
  def get_generation_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/generations/hash/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Generation{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a generation by height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - height (integer()): The height of the generation
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Generation{}} on success
  {:error, info} on failure
  """
  @spec get_generation_by_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, AeternityNode.Model.Generation.t()} | {:error, Tesla.Env.t()}
  def get_generation_by_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/generations/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Generation{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a key block by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.KeyBlock{}} on success
  {:error, info} on failure
  """
  @spec get_key_block_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.KeyBlock.t()} | {:error, Tesla.Env.t()}
  def get_key_block_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/hash/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.KeyBlock{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a key block by height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - height (integer()): The height of the block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.KeyBlock{}} on success
  {:error, info} on failure
  """
  @spec get_key_block_by_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, AeternityNode.Model.KeyBlock.t()} | {:error, Tesla.Env.t()}
  def get_key_block_by_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.KeyBlock{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a micro block header by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.MicroBlockHeader{}} on success
  {:error, info} on failure
  """
  @spec get_micro_block_header_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.MicroBlockHeader.t()} | {:error, Tesla.Env.t()}
  def get_micro_block_header_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/header")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.MicroBlockHeader{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a micro block transaction by hash and index

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - index (integer()): The index of the transaction in a block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.GenericSignedTx{}} on success
  {:error, info} on failure
  """
  @spec get_micro_block_transaction_by_hash_and_index(
          Tesla.Env.client(),
          String.t(),
          integer(),
          keyword()
        ) :: {:ok, AeternityNode.Model.GenericSignedTx.t()} | {:error, Tesla.Env.t()}
  def get_micro_block_transaction_by_hash_and_index(connection, hash, index, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/transactions/index/#{index}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.GenericSignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get micro block transactions by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.GenericTxs{}} on success
  {:error, info} on failure
  """
  @spec get_micro_block_transactions_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.GenericTxs.t()} | {:error, Tesla.Env.t()}
  def get_micro_block_transactions_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/transactions")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.GenericTxs{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get micro block transaction count by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.InlineResponse2002{}} on success
  {:error, info} on failure
  """
  @spec get_micro_block_transactions_count_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.InlineResponse2002.t()} | {:error, Tesla.Env.t()}
  def get_micro_block_transactions_count_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/micro-blocks/hash/#{hash}/transactions/count")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.InlineResponse2002{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get name entry from naming system

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - name (String.t): The name key of the name entry
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.NameEntry{}} on success
  {:error, info} on failure
  """
  @spec get_name_entry_by_name(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.NameEntry.t()} | {:error, Tesla.Env.t()}
  def get_name_entry_by_name(connection, name, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/names/#{name}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.NameEntry{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get an oracle by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the oracle
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.RegisteredOracle{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.RegisteredOracle.t()} | {:error, Tesla.Env.t()}
  def get_oracle_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/oracles/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.RegisteredOracle{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get oracle queries by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the oracle
  - opts (KeywordList): [optional] Optional parameters
    - :from (String.t): Last query id in previous page
    - :limit (integer()): Max number of oracle queries
    - :type (String.t): The type of a query: open, closed or all
  ## Returns

  {:ok, %AeternityNode.Model.OracleQueries{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_queries_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.OracleQueries.t()} | {:error, Tesla.Env.t()}
  def get_oracle_queries_by_pubkey(connection, pubkey, opts \\ []) do
    optional_params = %{
      :from => :query,
      :limit => :query,
      :type => :query
    }

    %{}
    |> method(:get)
    |> url("/oracles/#{pubkey}/queries")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.OracleQueries{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get an oracle query by public key and query ID

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the oracle
  - query_id (String.t): The ID of the query
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.OracleQuery{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_query_by_pubkey_and_query_id(
          Tesla.Env.client(),
          String.t(),
          String.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.OracleQuery.t()} | {:error, Tesla.Env.t()}
  def get_oracle_query_by_pubkey_and_query_id(connection, pubkey, query_id, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/oracles/#{pubkey}/queries/#{query_id}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.OracleQuery{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get peer public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.InlineResponse2003{}} on success
  {:error, info} on failure
  """
  @spec get_peer_pubkey(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.InlineResponse2003.t()} | {:error, Tesla.Env.t()}
  def get_peer_pubkey(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/peers/pubkey")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.InlineResponse2003{}}
    ])
  end

  @doc """
  Get pending account transactions by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.GenericTxs{}} on success
  {:error, info} on failure
  """
  @spec get_pending_account_transactions_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.GenericTxs.t()} | {:error, Tesla.Env.t()}
  def get_pending_account_transactions_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}/transactions/pending")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.GenericTxs{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get the pending key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.KeyBlock{}} on success
  {:error, info} on failure
  """
  @spec get_pending_key_block(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.KeyBlock.t()} | {:error, Tesla.Env.t()}
  def get_pending_key_block(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/key-blocks/pending")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.KeyBlock{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get the status of a node

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Status{}} on success
  {:error, info} on failure
  """
  @spec get_status(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.Status.t()} | {:error, Tesla.Env.t()}
  def get_status(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/status")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Status{}}
    ])
  end

  @doc """
  Get the top block (either key or micro block)

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.KeyBlockOrMicroBlockHeader{}} on success
  {:error, info} on failure
  """
  @spec get_top_block(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.KeyBlockOrMicroBlockHeader.t()} | {:error, Tesla.Env.t()}
  def get_top_block(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/blocks/top")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.KeyBlockOrMicroBlockHeader{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a transaction by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.GenericSignedTx{}} on success
  {:error, info} on failure
  """
  @spec get_transaction_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.GenericSignedTx.t()} | {:error, Tesla.Env.t()}
  def get_transaction_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/transactions/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.GenericSignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a transaction info by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.ContractCallObject{}} on success
  {:error, info} on failure
  """
  @spec get_transaction_info_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.ContractCallObject.t()} | {:error, Tesla.Env.t()}
  def get_transaction_info_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/transactions/#{hash}/info")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.ContractCallObject{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Post a new transaction

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (Tx): The new transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.PostTxResponse{}} on success
  {:error, info} on failure
  """
  @spec post_transaction(Tesla.Env.client(), AeternityNode.Model.Tx.t(), keyword()) ::
          {:ok, AeternityNode.Model.PostTxResponse.t()} | {:error, Tesla.Env.t()}
  def post_transaction(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/transactions")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.PostTxResponse{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end
end
