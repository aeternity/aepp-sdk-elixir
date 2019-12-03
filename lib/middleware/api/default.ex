defmodule Aeternal.Api.Default do
  @moduledoc """
  API calls for all endpoints tagged `Default`.
  """

  alias Aeternal.Connection
  import Aeternal.RequestBuilder

  @doc """
  Get Active Channel Names

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_active_channels(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_active_channels(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/channels/active")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a list of all the active name auctions

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
    - :length (integer()): returns the names with provided length
    - :reverse (String.t): no value needs to be provided. if present the response will be reversed
    - :limit (integer()): 
    - :page (integer()): 
    - :sort (String.t): Can be 'name', 'max_bid' or 'expiration'(default)
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_active_name_auctions(Tesla.Env.client(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_active_name_auctions(connection, opts \\ []) do
    optional_params = %{
      :length => :query,
      :reverse => :query,
      :limit => :query,
      :page => :query,
      :sort => :query
    }

    %{}
    |> method(:get)
    |> url("/names/auctions/active")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a count of all the active name auctions

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
    - :length (integer()): returns the names with provided length
    - :reverse (String.t): no value needs to be provided. if present the response will be reversed
    - :limit (integer()): 
    - :page (integer()): 
    - :sort (String.t): Can be 'name', 'max_bid' or 'expiration'(default)
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_active_name_auctions_count(Tesla.Env.client(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_active_name_auctions_count(connection, opts \\ []) do
    optional_params = %{
      :length => :query,
      :reverse => :query,
      :limit => :query,
      :page => :query,
      :sort => :query
    }

    %{}
    |> method(:get)
    |> url("/names/auctions/active/count")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a list of all the active names

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
    - :owner (String.t): Address of the owner account to filter the results
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_active_names(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_active_names(connection, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query,
      :owner => :query
    }

    %{}
    |> method(:get)
    |> url("/names/active")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get all the contracts

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_all_contracts(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_all_contracts(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/all")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  get all names

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_all_names(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_all_names(connection, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/names")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a list of oracles

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_all_oracles(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_all_oracles(connection, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/oracles/list")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get the current of size of blockchain 

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_chain_size(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_chain_size(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/size/current")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get all transactions for a state channel

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - address (String.t): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_channel_tx(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_channel_tx(connection, address, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/channels/transactions/address/#{address}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get list of compilers available to the middleware

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_compilers(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_compilers(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/compilers")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get contract calls for a provided contract

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - address (String.t): Contract Address/id
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_contract_address_calls(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_contract_address_calls(connection, address, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/calls/address/#{address}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get all the transactions for a contract

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - address (String.t): Contract Address/id
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_contract_tx(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_contract_tx(connection, address, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/contracts/transactions/address/#{address}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  get count of transactions at the current height

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_current_tx_count(Tesla.Env.client(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_current_tx_count(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/count/current")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get generations between a given range

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - from (integer()): Start Generation or Key Block Number
  - to (integer()): End Generation or Key Block Number
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_generations_by_range(Tesla.Env.client(), integer(), integer(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_generations_by_range(connection, from, to, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/generations/#{from}/#{to}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get block height at a given time(provided in milliseconds)

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - milliseconds (integer()): Time in milliseconds
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_height_by_time(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_height_by_time(connection, milliseconds, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/height/at/#{milliseconds}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  get middleware status

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_mdw_status(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def get_mdw_status(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/status")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get bids made by a given account

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - account (String.t): Account address
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_name_auctions_bidsby_address(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_name_auctions_bidsby_address(connection, account, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/names/auctions/bids/account/#{account}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a bids for a given name

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - name (String.t): Name to fetch the bids for
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_name_auctions_bidsby_name(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_name_auctions_bidsby_name(connection, name, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/names/auctions/bids/#{name}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a list of names mapped to the given address

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - account (String.t): Account address
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_name_by_address(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_name_by_address(connection, account, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/names/reverse/#{account}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a list of query and response for a given oracle

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - oracle_id (String.t): oracle address/id to get the query and responses
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_data(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_oracle_data(connection, oracle_id, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/oracles/#{oracle_id}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get the block reward for a given block height

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - height (integer()): Blockchain height
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_reward_at_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_reward_at_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/reward/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get size of blockchain at a given height

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - height (integer()): Blockchain height
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_size_at_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_size_at_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/size/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get a list of transactions between two accounts

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - sender (String.t): Sender account address
  - receiver (String.t): Receiver account address
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_tx_between_address(Tesla.Env.client(), String.t(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_tx_between_address(connection, sender, receiver, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/transactions/account/#{sender}/to/#{receiver}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get list of transactions for a given account

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - account (String.t): Account address
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_tx_by_account(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_tx_by_account(connection, account, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query
    }

    %{}
    |> method(:get)
    |> url("/transactions/account/#{account}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get transactions between an interval of generations

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - from (integer()): Start Generation/Key-block height
  - to (integer()): End Generation/Key-block height
  - opts (KeywordList): [optional] Optional parameters
    - :limit (integer()): 
    - :page (integer()): 
    - :txtype (String.t): Transaction Type
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_tx_by_generation_range(Tesla.Env.client(), integer(), integer(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_tx_by_generation_range(connection, from, to, opts \\ []) do
    optional_params = %{
      :limit => :query,
      :page => :query,
      :txtype => :query
    }

    %{}
    |> method(:get)
    |> url("/transactions/interval/#{from}/#{to}")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get the count of transactions for a given account address

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - address (String.t): Account address
  - opts (KeywordList): [optional] Optional parameters
    - :txtype (String.t): Transaction Type
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_tx_count_by_address(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_tx_count_by_address(connection, address, opts \\ []) do
    optional_params = %{
      :txtype => :query
    }

    %{}
    |> method(:get)
    |> url("/transactions/account/#{address}/count")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Get transaction amount and count for the date interval

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - from (String.t): Start Date(yyyymmdd)
  - to (String.t): End Date(yyyymmdd)
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec get_tx_rate_by_date_range(Tesla.Env.client(), String.t(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def get_tx_rate_by_date_range(connection, from, to, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/transactions/rate/#{from}/#{to}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Search for a name

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - name (String.t): String to match and find the name against
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec search_name(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def search_name(connection, name, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/names/#{name}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end

  @doc """
  Verify a contract by submitting the source, compiler version and contract identifier

  ## Parameters

  - connection (Aeternal.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
    - :contract (InlineObject): 
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec verify_contract(Tesla.Env.client(), keyword()) :: {:ok, nil} | {:error, Tesla.Env.t()}
  def verify_contract(connection, opts \\ []) do
    optional_params = %{
      :contract => :body
    }

    %{}
    |> method(:post)
    |> url("/contracts/verify")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false}
    ])
  end
end
