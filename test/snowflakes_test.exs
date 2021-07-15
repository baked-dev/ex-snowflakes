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

    res = "test_parent_c6df4ae7a44744cc438fef30c091"
    res2 = "test_child_761cf03a0e7ff4fc7344ced40370f42f740a10fb26"
    res3 = GenServer.call(pid, {:gen_parent, res2, "test_parent"})
    res4 = "test_nested_child_c626af0f9a0ae7f704f4173764d48d4ce7732f4f6f7ff0a060f0f361"
    res5 = GenServer.call(pid, {:gen_parent, res4, "test_child"})
    res6 = GenServer.call(pid, {:gen_parent, res5, "test_parent"})
    assert res5 == res2 and res6 == res
  end

  test "snowflakes from golang" do
    {:ok, pid} = Snowflakes.start_link("test_signing_key", 1023)

    res = "test_parent_d66f4a050ab53cf2837fdfb0c0c0"
    res2 = "test_child_f609f0ea0b5f8afe535c2b2c835bfa7f5c0ad0ff16"
    res3 = GenServer.call(pid, {:gen_parent, res2, "test_parent"})
    res4 = "test_nested_child_c616bf0f9a0ac5f57afae5358c2c42c2b3531faf7f5f20a0d0f09260"
    res5 = GenServer.call(pid, {:gen_parent, res4, "test_child"})
    res6 = GenServer.call(pid, {:gen_parent, res5, "test_parent"})
    assert res5 == res2 and res6 == res
  end
end
