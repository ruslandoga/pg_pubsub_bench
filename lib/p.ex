defmodule P do
  @moduledoc """
  Documentation for `P`.
  """

  defmodule Dummy do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, [], name: opts[:name] || __MODULE__)
    end

    def subscribe(server \\ __MODULE__, topic) do
      GenServer.call(server, {:subscribe, topic})
    end

    def join(server \\ __MODULE__, group) do
      GenServer.call(server, {:join, group})
    end

    @impl true
    def init(_opts), do: {:ok, nil}

    @impl true
    def handle_call({:subscribe, topic}, _from, state) do
      Phoenix.PubSub.subscribe(P.PubSub, topic)
      {:reply, :ok, state}
    end

    def handle_call({:join, group}, _from, state) do
      :pg.join(group, self())
      {:reply, :ok, state}
    end

    @impl true
    def handle_info(_message, state), do: {:noreply, state}
  end

  def connect_nodes(name \\ "pg_pubsub_bench.svc.pg_pubsub_bench.cluster") do
    :inet_res.lookup(to_charlist(name), :in, :srv)
    |> Enum.flat_map(fn {_, _, _, a} -> :inet_res.lookup(a, :in, :a) end)
    |> Enum.map(fn ip -> {ip, Node.connect(:"p@#{:inet.ntoa(ip)}")} end)
  end

  def wait_for_pg_members_count_to_be(count) do
    if :pg.get_members(:group) >= count do
      :ok
    else
      :timer.sleep(100)
      wait_for_pg_members_count_to_be(count)
    end
  end
end
