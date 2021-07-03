defmodule SnowflakesTest do
  use ExUnit.Case
  doctest Snowflakes

  test "nested child - parent relations" do
    {:ok, pid} = Snowflakes.start_link("test_signing_key", 1023)

    res = GenServer.call(pid, {:gen, "test"})
    res2 = GenServer.call(pid, {:gen, "test", res})
    res3 = GenServer.call(pid, {:gen_parent, res2, "test"})
    res4 = GenServer.call(pid, {:gen, "test", res2})
    res5 = GenServer.call(pid, {:gen_parent, res4, "test"})
    res6 = GenServer.call(pid, {:gen_parent, res5, "test"})
    assert res5 == res2 and res6 == res
  end

  test "snowflakes from js" do
    {:ok, pid} = Snowflakes.start_link("test_signing_key", 1023)

    res = "test_parent_d55fdb5a9fafcce42bffdf509074"
    res2 = "test_child_d547f01b09af7ff2fb5c4b4c8bfdff6fa90bf0f385"
    res3 = GenServer.call(pid, {:gen_parent, res2, "test_parent"})
    res4 = "test_nested_child_d584af003b007aff8fffbfbb7c4495cc13ff3fff5faa60bbe0ff8855"
    res5 = GenServer.call(pid, {:gen_parent, res4, "test_child"})
    res6 = GenServer.call(pid, {:gen_parent, res5, "test_parent"})
    assert res5 == res2 and res6 == res
  end
end
