Basic `:pg` vs `Phoenix.PubSub` bench over two `t4g.micro` EC2 instances in different AZs but in the same region.

#### Setup

```elixir
iex(p@10.0.102.150)1> P.connect_nodes()
[{{10, 0, 102, 150}, true}, {{10, 0, 103, 156}, true}]
```

#### Registration

```elixir
iex(p@10.0.102.150)2> :timer.tc fn -> Enum.each(1..10_000, fn i -> Phoenix.PubSub.subscribe(P.PubSub, "topic:#{i}") end) end
{93478, :ok}
```

```elixir
iex(p@10.0.102.150)3> :timer.tc fn ->
...(p@10.0.102.150)3>   :erpc.call(:"p@10.0.103.156", fn -> Enum.each(1..10_000, fn _ -> :pg.join(:group, self()) end) end)
...(p@10.0.102.150)3>   P.wait_for_pg_members_count_to_be(10_000)
...(p@10.0.102.150)3> end
{1410878, :ok}
```

### Broadcasting

```elixir
iex(p@10.0.102.150)4> Enum.each(1..10_000, fn i -> Phoenix.PubSub.unsubscribe(P.PubSub, "topic:#{i}") end)
:ok

iex(p@10.0.102.150)5> :erpc.call(:"p@10.0.103.156", fn -> Enum.each(1..10_000, fn i -> P.Dummy.subscribe("topic") end) end)
:ok

iex(p@10.0.102.150)6> :timer.tc fn -> Phoenix.PubSub.broadcast(P.PubSub, "topic", :hello) end
{24, :ok}
```

```elixir
iex(p@10.0.102.150)7> :erpc.call(:"p@10.0.103.156", fn -> Enum.each(1..10_000, fn _ -> P.Dummy.join(:group) end) end)
:ok

iex(p@10.0.102.150)8> :timer.tc fn -> Enum.each(:pg.get_members(:group), fn pid -> send(pid, :hello) end) end
{41658, :ok}
```
