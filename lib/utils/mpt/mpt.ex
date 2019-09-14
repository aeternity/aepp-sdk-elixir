defmodule Utils.MPTrees do
  @trees [:accounts, :calls, :channels, :contracts, :ns, :oracles]
  # [:accounts, :calls, :channels, :contracts, :ns, :oracles]
  defstruct @trees
  alias Utils.{MPTdb, MPTrees}

  @spec new_without_backend() :: struct()
  def new_without_backend() do
    new_struct_data = for tree <- @trees, do: {tree, new_tree(tree)}
    struct(__MODULE__, new_struct_data)
    # %__MODULE__{
    #   accounts: new_tree_accounts(),
    #   calls: new_tree_calls(),
    #   channels: new_tree_channels(),
    #   contracts: new_tree_contracts(),
    #   ns: new_tree_ns(),
    #   oracles: new_tree_oracles()
    # }
  end

  def enter(%MPTrees{} = tree, tree_type, key, value) do
  end

  def insert(%MPTrees{} = tree, tree_type, key, value) do
  end

  def delete(%MPTrees{} = tree, tree_type, key) do
  end

  def lookup(%MPTrees{} = tree, tree_type, key) do
  end

  def calculate_state_hash(%MPTrees{} = tree) do
  end

  # def calculate_poi_hash(%__MODULE__{} = tree) do

  # #   <<?VERSION:64,
  # #   (part_poi_hash(POI#poi.accounts)) /binary,
  # #   (part_poi_hash(POI#poi.calls))    /binary,
  # #   (part_poi_hash(POI#poi.channels)) /binary,
  # #   (part_poi_hash(POI#poi.contracts))/binary,
  # #   (part_poi_hash(POI#poi.ns))       /binary,
  # #   (part_poi_hash(POI#poi.oracles))  /binary
  # # >>
  # end

  defp new_tree(:accounts) do
    new_empty_tree()
  end

  defp new_tree(:calls) do
    %{calls: new_empty_tree()}
  end

  defp new_tree(:channels) do
    new_empty_tree()
  end

  defp new_tree(:contracts) do
    %{contracts: new_empty_tree()}
  end

  defp new_tree(:ns) do
    %{mtree: new_empty_tree(), cache: new_empty_tree()}
  end

  defp new_tree(:oracles) do
    %{otree: new_empty_tree(), cache: new_empty_tree()}
  end

  defp new_empty_tree() do
    %{hash: <<>>, db: MPTdb.new()}
  end
end
