defmodule Fwatch.Mixfile do
  use Mix.Project

  def project do
    [app: :fwatch,
     description: "A file watcher for Elixir",
     package: package,
     version: "0.5.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [mod: {Fwatch, []},
     applications: [:logger, :fs]]
  end

  defp deps do
    [{:ex_doc, "~> 0.11", only: :dev},
     {:fs, github: "synrc/fs", rev: "5bec73a9b968834cd77e1b3932ffa8321c984e87"}]
  end

  defp package do
    [maintainers: ["Ryo Hashiguchi"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/ryo33/fwatch-ex"}]
  end
end
