defmodule Fwatch do
  use Application
  use GenServer

  @root_dir File.cwd!

  @type name :: atom | pid
  @type pattern :: String.t | Regex.t
  @typedoc """
  Callback for file event.

  First argument is a path and second one is a list of events.
  See [Lists Events from Backend](https://github.com/synrc/fs#list-events-from-backend) for details of events.
  """
  @type callback :: (String.t, [atom] -> any)

  # files :: {:file, [any], callback}
  # dirs :: {:dir, [any], callback}

  # Application callback
  def start(_type, _args) do
    GenServer.start_link(__MODULE__, [], name: :fwatch)
  end

  @doc """
  Watch a specified directory.
  """
  def start_link(name, path) do
    fs_name = Atom.to_string(name) |> Kernel.<>("_fs") |> String.to_atom()
    :fs.start_link(fs_name, to_char_list(Path.expand(path, @root_dir)))
    GenServer.start_link(__MODULE__, {fs_name, []}, name: name)
  end

  # GenServer callbacks

  def init({name, state}) do
    :ok = :fs.subscribe(name)
    {:ok, state}
  end

  def init(state) do
    :ok = :fs.subscribe
    {:ok, state}
  end

  def handle_cast({:add_target, item}, targets) do
    {:noreply, [item|targets]}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, events}}, targets) do
    handle_file_event(targets, to_string(path), events)
    {:noreply, targets}
  end

  # Fwatch functions

  @doc """
  Registers callback for given files.
  """
  def watch_file(name \\ :fwatch, files, callback)

  @spec watch_file(name, [pattern], callback) :: any
  def watch_file(name, files, callback) when is_list(files) do
    pid = if is_atom(name), do: {name, node()}, else: name
    GenServer.cast(pid, {:add_target, {:file, files, callback}})
  end

  @spec watch_file(name, pattern, callback) :: any
  def watch_file(name, file, callback) do
    watch_file(name, [file], callback)
  end

  @doc """
  Registers the callback for given dirs.
  """
  def watch_dir(name \\ :fwatch, dirs, callback)

  @spec watch_dir(name, [pattern], callback) :: any
  def watch_dir(name, dirs, callback) when is_list(dirs) do
    pid = if is_atom(name), do: {name, node()}, else: name
    GenServer.cast(pid, {:add_target, {:dir, dirs, callback}})
  end

  @spec watch_dir(name, pattern, callback) :: any
  def watch_dir(name, dir, callback) do
    watch_dir(name, [dir], callback)
  end

  defp handle_file_event(targets, path, events) do
    Enum.map(targets, fn
      {:file, files, callback} ->
        if Enum.any?(files, &(match_file?(path, &1))) do
          spawn fn -> callback.(path, events) end
        end
      {:dir, dirs, callback} ->
        if Enum.any?(dirs, &(match_dir?(path, &1))) do
          spawn fn -> callback.(path, events) end
        end
    end)
  end

  defp match_file?(file, pattern) when is_binary(pattern), do: file == expath(pattern)
  defp match_file?(file, pattern) do
    cond do
      Regex.regex?(pattern) -> Regex.match?(pattern, file)
      true -> false
    end
  end

  defp match_dir?(file, pattern) when is_binary(pattern), do: contain_path?(Path.dirname(file), expath(pattern))
  defp match_dir?(file, pattern) do
    cond do
      Regex.regex?(pattern) -> Regex.match?(pattern, Path.dirname(file))
      true -> false
    end
  end

  defp contain_path?(path, target_path) do
    path1 = Path.split(path)
    path2 = Path.split(target_path)
    length = length(path2)
    cond do
      length(path1) < length -> false
      true -> Enum.slice(path1, 0, length) == path2
    end
  end

  defp expath(path), do: Path.expand(path, @root_dir)
end
