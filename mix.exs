defmodule ExAst.MixProject do
  use Mix.Project

  @source_url "https://github.com/dannote/ex_ast"

  def project do
    [
      app: :ex_ast,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Search and replace Elixir code by AST pattern",
      source_url: @source_url,
      package: package(),
      dialyzer: [
        plt_file: {:no_warn, "_build/dev/dialyxir_plt.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:sourceror, "~> 1.7"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
