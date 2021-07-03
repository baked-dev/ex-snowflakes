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
end
