defmodule FwatchTest do
  use ExUnit.Case
  doctest Fwatch

  setup do
    pid = Process.whereis(:fwatch)
    {:ok, agent} = Agent.start_link(fn -> [] end)
    {:ok, pid: pid, agent: agent}
  end

  defp send_file_event(pid, path, agent) do
    send pid, {self(), {:fs, :file_event}, {to_char_list(path), :created}}
    :timer.sleep(50)
    result = Agent.get(agent, fn x -> x end)
    Agent.update(agent, fn _ -> [] end)
    result
  end

  defp update_func(pid) do
    fn path, event ->
      Agent.update(pid, fn x -> [{path, event} | x] end)
    end
  end

  defp update_func(pid, key) do
    fn path, event ->
      Agent.update(pid, fn x -> [{key, path, event} | x] end)
    end
  end

  test "watch_file", %{pid: pid, agent: agent} do
    Fwatch.watch_file(["/a/b/c", ~r(^/b/.*$)], update_func(agent))

    status = send_file_event(pid, "/a/b/d", agent)
    assert length(status) == 0

    status = send_file_event(pid, "/c/d", agent)
    assert length(status) == 0

    status = send_file_event(pid, "/a/b/c", agent)
    assert length(status) == 1
    assert hd(status) == {"/a/b/c", :created}

    status = send_file_event(pid, "/b/c", agent)
    assert length(status) == 1
    assert hd(status) == {"/b/c", :created}
  end

  test "watch_dir", %{pid: pid, agent: agent} do
    Fwatch.watch_dir(["/a/b/c", ~r(^/b/.*$)], update_func(agent))

    status = send_file_event(pid, "/a/b/c", agent)
    assert length(status) == 0

    status = send_file_event(pid, "/b/c", agent)
    assert length(status) == 0

    status = send_file_event(pid, "/a/b/c/d", agent)
    assert length(status) == 1
    assert hd(status) == {"/a/b/c/d", :created}

    status = send_file_event(pid, "/b/c/d", agent)
    assert length(status) == 1
    assert hd(status) == {"/b/c/d", :created}

    status = send_file_event(pid, "/a/b/c/d/e", agent)
    assert length(status) == 1
    assert hd(status) == {"/a/b/c/d/e", :created}

    status = send_file_event(pid, "/b/c/d/e", agent)
    assert length(status) == 1
    assert hd(status) == {"/b/c/d/e", :created}
  end

  test "multi handlers", %{pid: pid, agent: agent} do
    Fwatch.watch_file(["/a/b/c", ~r(^/b/.*$)], update_func(agent, :a))
    Fwatch.watch_file(~r(^/a/b/.*$), update_func(agent, :b))
    Fwatch.watch_dir(["/a/b", ~r(^/b/.*$)], update_func(agent, :c))
    Fwatch.watch_dir(["/a", "/b/c"], update_func(agent, :d))

    status = send_file_event(pid, "/a/b/c", agent)
    assert length(status) == 4
    assert Enum.at(status, 0) == {:a, "/a/b/c", :created}
    assert Enum.at(status, 1) == {:b, "/a/b/c", :created}
    assert Enum.at(status, 2) == {:c, "/a/b/c", :created}
    assert Enum.at(status, 3) == {:d, "/a/b/c", :created}

    status = send_file_event(pid, "/a/b", agent)
    assert length(status) == 1
    assert Enum.at(status, 0) == {:d, "/a/b", :created}

    status = send_file_event(pid, "/a", agent)
    assert length(status) == 0

    status = send_file_event(pid, "/b/c/d", agent)
    assert length(status) == 3
    assert Enum.at(status, 0) == {:a, "/b/c/d", :created}
    assert Enum.at(status, 1) == {:c, "/b/c/d", :created}
    assert Enum.at(status, 2) == {:d, "/b/c/d", :created}

    status = send_file_event(pid, "/b/c", agent)
    assert length(status) == 1
    assert Enum.at(status, 0) == {:a, "/b/c", :created}
  end
end
