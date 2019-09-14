defmodule Utils.POI do
  alias Utils.{MPTdb, POI}
  @root_hash_size 32
  # @trees [:accounts, :calls, :channels, :contracts, :ns, :oracles]
  defstruct proof: MPTdb.new(), hash: <<>>

  def new(root_hash) when byte_size(root_hash) == @root_hash_size do
    %POI{proof: MPTdb.new(), hash: root_hash}
  end
end
