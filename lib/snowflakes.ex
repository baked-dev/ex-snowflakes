defmodule Snowflakes do
  use GenServer
  use Bitwise

  defstruct signing_key: nil,
            node_id: 1023,
            seq: 0

  def start_link(signing_key, node_id) do
    GenServer.start_link(
      __MODULE__,
      %__MODULE__{signing_key: signing_key, node_id: node_id, seq: 0},
      name: :snowflakes
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:gen, type}, _from, state) do
    flake = gen(state.signing_key, state.node_id, state.seq, type)
    {:reply, flake, %{state | seq: state.seq + 1 &&& 4095}}
  end

  def handle_call({:gen, type, parent}, _from, state) when is_binary(parent) do
    flake = gen(state.signing_key, state.node_id, state.seq, type, parent)
    {:reply, flake, %{state | seq: state.seq + 1 &&& 4095}}
  end

  def handle_call({:verify, snowflake}, _from, state) when is_binary(snowflake) do
    res = verify(state.signing_key, snowflake)
    {:reply, res, state}
  end

  def handle_call({:gen_parent, snowflake, type}, _from, state) when is_binary(snowflake) do
    res = gen_parent(state.signing_key, snowflake, type)
    {:reply, res, state}
  end

  def gen(signing_key, node_id, seq, type, payloads) when is_list(payloads) do
    payloads = Enum.map(payloads, fn el -> String.reverse(el) end)

    ts =
      (:os.system_time(:millisecond) - 1_618_868_000_000)
      |> Integer.to_string(2)
      |> String.pad_leading(48, "0")

    node_id_bin =
      (node_id &&& 1023)
      |> Integer.to_string(2)
      |> String.pad_leading(10, "0")

    bin_seq =
      (seq &&& 4095)
      |> Integer.to_string(2)
      |> String.pad_leading(12, "0")

    bin = "#{ts}#{node_id_bin}#{bin_seq}"

    hex =
      bin
      |> String.to_integer(2)
      |> Integer.to_string(16)
      |> String.downcase()

    payloads = [hex | payloads]
    "#{type}_#{sign(signing_key, type, payloads)}"
  end

  def gen(signing_key, node_id, seq, type, parent) when is_binary(parent) do
    {:ok, _type, data, _sig, _ts, _seq, parents} = read(parent)
    gen(signing_key, node_id, seq, type, [data | parents])
  end

  def gen(signing_key, node_id, seq, type) do
    gen(signing_key, node_id, seq, type, [])
  end

  def gen(signing_key, type) do
    gen(signing_key, 1023, 0, type, [])
  end

  def gen(signing_key, type, parent) when is_binary(parent) do
    gen(signing_key, 1023, 0, type, parent)
  end

  def gen_parent(signing_key, snowflake, type) do
    with {:ok, _type, _data, _sig, _ts, _seq, [data | parents]} <- read(snowflake) do
      parents = Enum.map(parents, fn el -> String.reverse(el) end)
      "#{type}_#{sign(signing_key, type, [data] ++ parents)}"
    end
  end

  def sign(signing_key, type, payloads) do
    get_signature(signing_key, type, payloads)
    |> String.split(~r//)
    |> Enum.filter(fn element ->
      String.length(element) > 0
    end)
    |> Enum.slice(0..(String.length(Enum.at(payloads, 0)) - 1))
    |> Enum.scan([], fn val, acc ->
      idx = length(acc)

      payload_data =
        Enum.scan(payloads, [], fn val2, _acc2 ->
          String.at(val2, idx)
        end)
        |> Enum.reduce(fn val3, acc3 ->
          "#{acc3}#{val3}"
        end)

      ["#{val}#{payload_data}" | acc]
    end)
    |> List.last()
    |> Enum.reverse()
    |> Enum.join("")
  end

  def get_signature(signing_key, type, payloads) do
    data =
      Enum.reduce(payloads, fn payload, acc ->
        "#{acc}#{payload}"
      end)

    :crypto.hash(:sha256, "#{data}#{signing_key}#{type}")
    |> Base.encode16()
    |> String.downcase()
  end

  def verify(signing_key, snowflake) do
    {:ok, type, data, sig, ts, seq, parents} = read(snowflake)

    reversed_parents = Enum.map(parents, fn el -> String.reverse(el) end)
    arg = [data] ++ reversed_parents
    signature = get_signature(signing_key, type, arg)

    case String.starts_with?(signature, sig) do
      true ->
        {:ok, type, data, sig, ts, seq, parents}

      _ ->
        {:err, "invalid_signature"}
    end
  end

  def read(snowflake) do
    [type, raw] = String.split(snowflake, ~r/_(?!.*_)/)

    amount =
      (String.length(raw) / 14)
      |> floor

    split =
      String.split(raw, ~r//)
      |> Enum.filter(fn element ->
        String.length(element) > 0
      end)

    split =
      split
      |> Enum.with_index(0)

    [sig, data | parents] =
      Enum.reduce(0..(amount - 1), [], fn idx, acc ->
        res =
          Enum.reduce(split, "", fn {element, index}, acc2 ->
            if rem(index, amount) == idx do
              "#{acc2}#{element}"
            else
              acc2
            end
          end)

        [res | acc]
      end)
      |> Enum.reverse()

    parents =
      Enum.map(parents, fn element ->
        String.reverse(element)
      end)

    bin_data =
      String.to_integer(data, 16)
      |> Integer.to_string(2)
      |> String.pad_leading(70, "0")

    ts =
      String.slice(bin_data, 0..47)
      |> String.to_integer(2)

    ts = ts + 1_618_868_000_000

    seq =
      String.slice(bin_data, 58..70)
      |> String.to_integer(2)

    {:ok, type, data, sig, ts, seq, parents}
  end
end
