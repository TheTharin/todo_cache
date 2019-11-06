defmodule Todo.Server do
  use GenServer, restart: :temporary

  def init(todo_list_name) do
    GenServer.cast(self(), {:real_init, todo_list_name})
    {:ok, nil}
  end

  def start_link(todo_list_name) do
    IO.puts("Starting todo server #{todo_list_name}")
    GenServer.start_link(__MODULE__, todo_list_name, name: via_tuple(todo_list_name))
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date: date})
  end

  def entries(pid) do
    GenServer.call(pid, {:entries})
  end

  def add_entry(pid, date: date, title: title) do
    case entry = Todo.Entry.new(date, title) do
      {:error, message} -> {:error, message}
      _ -> GenServer.cast(pid, {:add_entry, entry: entry})
    end
  end

  def add_entry(_, _) do
    IO.puts("The entry must be in format [date: date, title: title]")
  end

  def update_entry(pid, %Todo.Entry{} = new_entry) do
    GenServer.cast(pid, {:update_entry, new_entry: new_entry})
  end

  def delete_entry(pid, id) do
    GenServer.cast(pid, {:delete_entry, id: id})
  end

  def handle_call({:entries, date: date}, _, state = {_, todo_list}) do
    case entries = Todo.List.entries(todo_list, date) do
      {:error, message} -> {:reply, {:error, message}, todo_list}
      _ -> {:reply, entries, state}
    end
  end

  def handle_call({:entries}, _, state = {_, todo_list}) do
    entries = Todo.List.entries(todo_list)

    {:reply, entries, state}
  end

  def handle_cast({:real_init, todo_list_name}, _) do
    {:noreply, {todo_list_name, Todo.Database.get(todo_list_name) || Todo.List.new()}}
  end

  def handle_cast({:add_entry, entry: entry}, state = {name, todo_list}) do
    case new_todo_list = Todo.List.add_entry(todo_list, entry) do
      {:error, message} ->
        {:reply, {:error, message}, state}

      %Todo.List{} ->
        Todo.Database.store(name, new_todo_list)
        {:noreply, state}
    end
  end

  def handle_cast({:update_entry, new_entry: new_entry}, state = {name, todo_list}) do
    case new_todo_list = Todo.List.update_entry(todo_list, new_entry) do
      {:error, message} ->
        {:reply, {:error, message}, state}

      %Todo.List{} ->
        Todo.Database.store(name, new_todo_list)
        {:noreply, state}
    end
  end

  def handle_cast({:delete_entry, id: id}, state = {name, todo_list}) do
    new_todo_list = Todo.List.delete_entry(todo_list, id)

    Todo.Database.store(name, new_todo_list)
    {:noreply, state}
  end

  defp via_tuple(todo_list_name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, todo_list_name})
  end
end
