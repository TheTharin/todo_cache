defmodule TodoCacheTest do
  use ExUnit.Case

  test "server_process" do
    {:ok, cache} = Todo.Cache.start()
    bob_pid = Todo.Cache.server_process(cache, "Bob")

    assert bob_pid != Todo.Cache.server_process(cache, "Tom")
    assert bob_pid == Todo.Cache.server_process(cache, "Bob")
  end

  test "to-do operations" do
    {:ok, cache} = Todo.Cache.start()
    alice = Todo.Cache.server_process(cache, "Alice")
    Todo.Server.add_entry(alice, date: ~D[2019-11-21], title: "See doctor")
    entries = Todo.Server.entries(alice, ~D[2019-11-21])

    assert [%{date: ~D[2019-11-21], title: "See doctor"}] = entries
  end
end
