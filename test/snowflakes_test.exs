defmodule SnowflakesTest do
  use ExUnit.Case
  doctest Snowflakes

  test "reads snowflake" do
    flake = Snowflakes.gen("test_signing_key", "test")
    IO.puts(flake)

    flake2 = Snowflakes.gen("test_signing_key", "test", flake)
    IO.puts(flake2)

    sig = Snowflakes.sign("test_signing_key", "test", ["5f69cb16bff000"])
    IO.puts(sig)

    read = Snowflakes.read("test_child_9541f0f80f3fb5f1e7c66966b7eaf54f340880ff45")
    IO.inspect(read)

    verify =
      Snowflakes.verify(
        "test_signing_key",
        "test_child_9541f0f80f3fb5f1e7c66966b7eaf54f340880ff45"
      )

    IO.inspect(verify)

    {:ok, pid} = Snowflakes.start_link("test_signing_key", 1023)

    res = GenServer.call(pid, {:gen, "test"})
    res2 = GenServer.call(pid, {:gen, "test", res})
    res3 = GenServer.call(pid, {:gen_parent, res2, "test"})
    IO.inspect(res)
    IO.inspect(res2)
    IO.inspect(res3)
  end
end
