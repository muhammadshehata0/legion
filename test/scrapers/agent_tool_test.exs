defmodule Legion.Test.Scrapers.AgentToolTest do
  use ExUnit.Case
  import Legion.Test.IntegrationHelpers

  alias Legion.Test.Scrapers.Agents.{HackerNewsAgent, RedditAgent}
  alias Legion.Tools.AgentTool

  @moduletag :integration
  @moduletag timeout: 120_000
  @moduletag :skip

  describe "call/2" do
    test "calls HackerNews agent and gets result" do
      with_api_key do
        result = AgentTool.call(HackerNewsAgent, "Search for 'Elixir' posts, limit to 5")

        assert match?({:ok, _}, result) or match?({:cancel, _}, result)

        case result do
          {:ok, data} ->
            assert Map.has_key?(data, :posts_found)
            assert Map.has_key?(data, :top_posts)
            assert Map.has_key?(data, :sentiment_summary)
            assert is_integer(data.posts_found)
            assert is_list(data.top_posts)
            assert is_binary(data.sentiment_summary)

          {:cancel, reason} ->
            assert reason in [:reached_max_iterations, :reached_max_retries]
        end
      end
    end

    test "calls Reddit agent and gets result" do
      with_api_key do
        result = AgentTool.call(RedditAgent, "Search for 'Elixir' posts, limit to 5")

        assert match?({:ok, _}, result) or match?({:cancel, _}, result)

        case result do
          {:ok, data} ->
            assert Map.has_key?(data, :posts_found)
            assert Map.has_key?(data, :top_posts)
            assert Map.has_key?(data, :sentiment_summary)

          {:cancel, reason} ->
            assert reason in [:reached_max_iterations, :reached_max_retries]
        end
      end
    end
  end

  describe "concurrent agent calls" do
    test "can call multiple agents concurrently" do
      with_api_key do
        hn_task =
          Task.async(fn ->
            AgentTool.call(HackerNewsAgent, "Search for 'Elixir' posts, limit to 5")
          end)

        reddit_task =
          Task.async(fn ->
            AgentTool.call(RedditAgent, "Search for 'Elixir' posts, limit to 5")
          end)

        hn_result = Task.await(hn_task, 90_000)
        reddit_result = Task.await(reddit_task, 90_000)

        assert match?({:ok, _}, hn_result) or match?({:cancel, _}, hn_result)
        assert match?({:ok, _}, reddit_result) or match?({:cancel, _}, reddit_result)
      end
    end
  end
end
