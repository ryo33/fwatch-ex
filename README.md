# Fwatch

A file watcher for Elixir.

## Installation

The package can be installed as:

  1. Add fwatch to your list of dependencies in `mix.exs`:
    ```
    def deps do
      [{:fwatch, "~> 0.1.0"}]
    end
    ```

  2. Ensure fwatch is started before your application:
    ```
    def application do
      [applications: [:fwatch]]
    end
    ```

## Usage

### Examples
```elixir
# Watch a file and registers a callback
Fwatch.watch_file("filename", fn path, events ->
  if :modified in events do
    IO.puts("#{path} is modified")
  end
end)
# Watch multiple files and registers a callback
Fwatch.watch_file(["filename1", "filename2"], callback)
# Watch a directory and registers a callback
Fwatch.watch_dir("dirname", callback)
# Watch multiple directories and registers a callback
Fwatch.watch_dir(["dirname1", "dirname2"], callback)
```
See [Lists Events from Backend](https://github.com/synrc/fs#list-events-from-backend) for details of events.

You can also use regular expressions as a filename or dirname like this:  
`Fwatch.watch_file(~r"/User/tmp/.*", callback)`
