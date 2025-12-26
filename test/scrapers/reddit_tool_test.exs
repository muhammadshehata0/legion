defmodule Legion.Test.Scrapers.Tools.RedditToolTest do
  use ExUnit.Case, async: true

  alias Legion.Test.Scrapers.Tools.RedditTool

  describe "extract_sentiment/1" do
    test "extracts positive words" do
      text = "This is great and awesome"
      sentiment = RedditTool.extract_sentiment(text)

      assert "great" in sentiment.positive
      assert "awesome" in sentiment.positive
    end

    test "extracts negative words" do
      text = "This is bad and terrible"
      sentiment = RedditTool.extract_sentiment(text)

      assert "bad" in sentiment.negative
      assert "terrible" in sentiment.negative
    end

    test "extracts both positive and negative words" do
      text = "The API is great but the documentation is terrible"
      sentiment = RedditTool.extract_sentiment(text)

      assert "great" in sentiment.positive
      assert "terrible" in sentiment.negative
    end

    test "returns empty lists when no sentiment words found" do
      text = "This is a neutral statement"
      sentiment = RedditTool.extract_sentiment(text)

      assert sentiment.positive == []
      assert sentiment.negative == []
    end

    test "is case insensitive" do
      text = "GREAT and AWFUL"
      sentiment = RedditTool.extract_sentiment(text)

      assert "great" in sentiment.positive
      assert "awful" in sentiment.negative
    end
  end

  describe "fetch_posts/3" do
    @tag :external_api
    @tag :skip
    test "returns a list of posts" do
      posts = RedditTool.fetch_posts("Elixir", "elixir", 5)
      assert is_list(posts)
    end

    @tag :external_api
    @tag :skip
    test "respects the limit parameter" do
      posts = RedditTool.fetch_posts("Elixir", "elixir", 3)
      assert length(posts) <= 3
    end

    @tag :external_api
    @tag :skip
    test "each post has required fields" do
      posts = RedditTool.fetch_posts("Elixir", "elixir", 5)

      if length(posts) != [] do
        post = hd(posts)
        assert Map.has_key?(post, :title)
        assert Map.has_key?(post, :url)
        assert Map.has_key?(post, :score)
        assert Map.has_key?(post, :source)
        assert post.source == "Reddit r/elixir"
      end
    end

    @tag :external_api
    @tag :skip
    test "can search different subreddits" do
      posts = RedditTool.fetch_posts("programming", "programming", 5)
      assert is_list(posts)

      if length(posts) != [] do
        post = hd(posts)
        assert post.source == "Reddit r/programming"
      end
    end
  end
end
