defmodule SnowflakesTest do
  use ExUnit.Case
  doctest Snowflakes

  test "nested child - parent relations" do
    {:ok, pid} = Snowflakes.start_link("test_signing_key", 1023)

    res = GenServer.call(pid, {:gen, "test_parent"})
    IO.inspect(res)
    res2 = GenServer.call(pid, {:gen, "test_child", res})
    IO.inspect(res2)
    res3 = GenServer.call(pid, {:gen_parent, res2, "test_parent"})
    res4 = GenServer.call(pid, {:gen, "test_nested_child", res2})
    IO.inspect(res4)
    res5 = GenServer.call(pid, {:gen_parent, res4, "test_child"})
    res6 = GenServer.call(pid, {:gen_parent, res5, "test_parent"})
    assert res5 == res2 and res6 == res
  end

  test "snowflakes from js" do
    {:ok, pid} = Snowflakes.start_link("test_signing_key", 1023)

    res = "test_parent_d50f0c52c8d0268bef7f0fc03004"
    res2 = "test_child_5545f08c032f18fc0fd6beb63f07f85f2b0c90f585"
    res3 = GenServer.call(pid, {:gen_parent, res2, "test_parent"})
    res4 = "test_nested_child_0585ef0fac0ce2f268f880f0e6b64b6b8f0faf8f9f2fa0c0d0f0b854"
    res5 = GenServer.call(pid, {:gen_parent, res4, "test_child"})
    res6 = GenServer.call(pid, {:gen_parent, res5, "test_parent"})
    assert res5 == res2 and res6 == res
  end
end
