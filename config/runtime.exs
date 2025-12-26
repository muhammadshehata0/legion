import Config
import Dotenvy

if config_env() == :test do
  source!([
    Path.absname(".env.test"),
    System.get_env()
  ])
  |> Enum.each(fn {key, value} -> System.put_env(key, value) end)
end

if config_env() == :prod do
  config :legion,
    model: System.get_env("LEGION_MODEL") || "openai:gpt-4o"
end
