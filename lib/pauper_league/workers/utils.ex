defmodule PauperLeague.Workers.Utils do
  @validators %{
    boolean: &is_boolean/1,
    list: &is_list/1,
    map: &is_map/1,
    integer: &is_integer/1,
    string: &is_binary/1
  }

  def get_value(map, key, type) do
    validator = Map.fetch!(@validators, type)
    value = map |> Map.get(key)

    is_correct_type = validator.(value)

    cond do
      is_nil(value) ->
        {:error, "No #{key} value in event obj: #{inspect(map)}"}

      not is_correct_type ->
        {:error, "Value: #{inspect(value)} for Key: #{key} -- not type #{inspect(type)}"}

      true ->
        {:ok, value}
    end
  end
end
