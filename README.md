Basic `:pg` vs `Phoenix.PubSub` bench over two `t4g.micro` EC2 instances in different AZs but in the same region.

#### Setup

```elixir
iex(p@10.0.102.150)1> P.connect_nodes()
[{{10, 0, 102, 150}, true}, {{10, 0, 103, 156}, true}]

iex(p@10.0.102.150)2> P.peer()
:"p@10.0.103.156"
```

#### Registration

Using `Phoenix.PubSub` we don't need to wait other nodes acking out subscription:

```elixir
iex(p@10.0.102.150)3> :timer.tc fn -> :erpc.call(P.peer(), fn -> Enum.each(1..10_000, fn _ -> P.Dummy.subscribe("topic") end) end) end
{83403, :ok}
```

With `:pg` joining the group is not over until we get it fully replicated locally:

```elixir
iex(p@10.0.102.150)4> :timer.tc fn ->
...(p@10.0.102.150)4>   :erpc.call(P.peer(), fn -> Enum.each(1..10_000, fn _ -> P.Dummy.join(:group) end) end)
...(p@10.0.102.150)4>   P.wait_for_pg_members_count_to_be(10_000)
...(p@10.0.102.150)4> end
{4204982, :ok}
```

#### Broadcasting

`Phoenix.PubSub` doesn't send duplicate messages when broadcasting to multiple subscribers on another node:

```elixir
iex(p@10.0.102.150)5> :timer.tc fn -> Phoenix.PubSub.broadcast(P.PubSub, "topic", :hello) end
{24, :ok}
```

Using `:pg` we need to send message to each member of the group:

```elixir
iex(p@10.0.102.150)6> :timer.tc fn -> Enum.each(:pg.get_members(:group), fn pid -> send(pid, :hello) end) end
{41658, :ok}
```
