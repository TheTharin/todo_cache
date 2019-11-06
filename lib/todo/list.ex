defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}
  def new(), do: %Todo.List{}

  def entries(todo_list, %Date{} = date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def entries(_, _), do: {:error, :date_is_not_provided}

  def entries(todo_list) do
    todo_list.entries
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def add_entry(todo_list, %Todo.Entry{} = entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)

    new_entries =
      Map.put(
        todo_list.entries,
        todo_list.auto_id,
        entry
      )

    %Todo.List{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def add_entry(_, _), do: {:error, :entry_is_not_a_struct}

  def update_entry(todo_list, %Todo.Entry{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(_, _) do
    {:error, :should_be_a_valid_todo_entry}
  end

  defp update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    new_entries =
      Map.delete(
        todo_list.entries,
        entry_id
      )

    %Todo.List{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end
end

defimpl Collectable, for: Todo.List do
  def into(original) do
    {original, &into_callback/2}
  end

  def into_callback(todo_list, {:cont, entry}) do
    Todo.List.add_entry(todo_list, entry)
  end

  def into_callback(todo_list, :done), do: todo_list
  def into_callback(_, :halt), do: :ok
end
