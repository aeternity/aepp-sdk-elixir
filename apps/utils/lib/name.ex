defmodule Utils.Name do
  @moduledoc """
  Contains all name-related utilities.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `Core.Client.new/4`
  """

  alias AeternityNode.Model.{CommitmentId, NameEntry}
  alias AeternityNode.Api.NameService
  alias Core.Client

  @doc """
  Creates name commitment hash .

  ## Examples
      iex> Utils.Name.commitment_id(client, "a123.test", 7)
      "cm_2rxmhXWBzjsXTsLfxYK5dqGxKzcJphSijJ3TVHe23mVWYJZhTY"
  """
  @spec commitment_id(Client.t(), String.t(), integer()) :: String.t() | {:error, String.t()}
  def commitment_id(%Client{connection: connection}, name, name_salt)
      when is_binary(name) and is_integer(name_salt) do
    case NameService.get_commitment_id(connection, name, name_salt) do
      {:ok, %CommitmentId{commitment_id: commitment_id}} -> commitment_id
      error -> error
    end
  end

  @doc """
  Lookups the information about the given name .

  ## Examples
      iex> Utils.Name.commitment_id(client, "a123.test", 7)
      {:ok, %AeternityNode.Model.Error{reason: "Name revoked"}}
  """
  @spec get_name_id_by_name(Client.t(), String.t()) :: String.t() | {:error, String.t()}
  def get_name_id_by_name(%Client{connection: connection}, name) when is_binary(name) do
    case NameService.get_name_entry_by_name(connection, name) do
      {:ok, %NameEntry{id: id}} -> id
      error -> error
    end
  end
end
