defmodule Todo.Entry do
  @enforce_keys [:date, :title]
  defstruct [:id, :date, :title]
  def new(%Date{} = date, title) when is_binary(title), do: %Todo.Entry{date: date, title: title}
  def new(%Date{}, _), do: {:error, :title_is_not_binary}
  def new(_, _), do: {:error, :date_is_not_date_type}
end
