defmodule Utils.MPTdb do
  defstruct [:handle, :cache, :get, :put, :drop_cache]
  alias __MODULE__
  @get_specification {:aeu_mp_trees, :dict_db_get}
  @put_specification {:aeu_mp_trees, :dict_db_put}
  @drop_cache_specification {:aeu_mp_trees, :dict_db_drop_cache}
  def new() do
    %MPTdb{
      handle: :dict.new(),
      cache: :dict.new(),
      get: @get_specification,
      put: @put_specification,
      drop_cache: @drop_cache_specification
    }
  end

  # defp dict_db_spec() do

  # end
end
