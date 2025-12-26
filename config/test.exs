import Config

config :legion,
  model: "openai:gpt-4o-mini",
  timeout: 10_000,
  max_iterations: 5,
  max_retries: 2
