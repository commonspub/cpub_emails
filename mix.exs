defmodule CommonsPub.Emails.MixProject do
  use Mix.Project

  def project do
    [
      app: :cpub_emails,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:pointers, "~> 0.4.2"},
      {:pointers, git: "https://github.com/commonspub/pointers", branch: "main"},
      # {:pointers, path: "../pointers"},
      # {:flexto, "~> 0.2"},
    ]
  end
end
