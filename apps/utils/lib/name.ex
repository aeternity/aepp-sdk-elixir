defmodule Utils.Name do
  @split_name_symbol "."
  @name_registrars [@split_name_symbol <> "test"]
  @name_split_check 2
  @max_name_length 253
  @max_label_length 63
  # 33?
  @hash_bytes_size 32

  @spec commitment_hash(String.t(), integer()) :: {:ok, binary()} | {:error, String.t()}
  def commitment_hash(name, name_salt) when is_integer(name_salt) do
    case normalize_and_validate_name(name) do
      {:ok, normalized_name} ->
        {:ok, hash_name} = normalized_namehash(normalized_name)
        {:ok, hash_blake2b(hash_name <> <<name_salt::integer-size(256)>>)}

      {:error, _} = error ->
        error
    end
  end

  @spec hash_blake2b(binary()) :: binary()
  def hash_blake2b(data) when is_binary(data) do
    {:ok, hash} = :enacl.generichash(@hash_bytes_size, data)
    hash
  end

  @spec normalized_namehash(String.t()) :: {:ok, binary()} | {:error, String.t()}
  def normalized_namehash(name) do
    case normalize_and_validate_name(name) do
      {:ok, normalized_name} -> {:ok, namehash(normalized_name)}
      {:error, _} = error -> error
    end
  end

  @spec normalize_and_validate_name(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def normalize_and_validate_name(name) do
    case validate_normalized_name(name) do
      :ok ->
        {:ok, normalize_name(name)}

      {:error, _} = error ->
        error
    end
  end

  @spec normalize_name(String.t() | term()) :: String.t() | {:error, String.t()}
  def normalize_name(name) when is_binary(name) do
    with charlist <- String.to_charlist(name),
         idna_encoded_string <-
           to_string(:idna.encode(charlist, [{:uts46, true}, {:std3_rules, true}])),
         length_idna_splitted_string <-
           length(String.split(idna_encoded_string, @split_name_symbol)),
         true <- length_idna_splitted_string == @name_split_check do
      idna_encoded_string
    else
      false -> {:error, "#{__MODULE__} No label in registrar"}
      error -> {:error, "#{__MODULE__} Illegal normalize_name call: #{inspect(error)}"}
    end
  end

  def normalize_name(name) do
    {:error, "#{__MODULE__} Invalid input data: #{name} must be type string"}
  end

  @spec namehash(String.t()) :: binary()
  defp namehash(name) do
    if name == "" do
      <<0::256>>
    else
      name
      |> String.split(@split_name_symbol)
      |> Enum.reverse()
      |> hash_labels()
    end
  end

  defp hash_labels([]), do: <<0::256>>

  defp hash_labels([label | rest]) do
    label_hash = hash_blake2b(label)
    rest_hash = hash_labels(rest)
    hash_blake2b(<<rest_hash::binary, label_hash::binary>>)
  end

  @spec validate_normalized_name(String.t()) :: :ok | {:error, String.t()}
  defp validate_normalized_name(name) do
    allowed_registrar =
      @name_registrars
      |> Enum.any?(fn registrar ->
        name_split_count =
          name
          |> String.split(@split_name_symbol)
          |> Enum.count()

        String.ends_with?(name, registrar) &&
          name_split_count == @name_split_check
      end)

    if allowed_registrar do
      validate_name_length(name)
    else
      {:error,
       "#{__MODULE__}: name doesn't end with allowed registrar: #{inspect(name)} or consists of multiple namespaces"}
    end
  end

  @spec validate_name_length(String.t()) :: :ok | {:error, String.t()}
  defp validate_name_length(name) do
    if String.length(name) > 0 && String.length(name) < @max_name_length do
      name
      |> split_name()
      |> validate_label_length()
    else
      {:error, "#{__MODULE__}: name has not the correct length: #{inspect(name)}"}
    end
  end

  @spec split_name(String.t()) :: [String.t()]
  defp split_name(name), do: String.split(name, @split_name_symbol)

  @spec validate_label_length([]) :: :ok
  defp validate_label_length([]) do
    :ok
  end

  @spec validate_label_length(list(String.t())) :: :ok | {:error, String.t()}
  defp validate_label_length([label | remainder]) do
    case String.length(label) > 0 && String.length(label) <= @max_label_length do
      true -> validate_label_length(remainder)
      false -> {:error, "#{__MODULE__}: label has not the correct length: #{inspect(label)}"}
    end
  end
end
