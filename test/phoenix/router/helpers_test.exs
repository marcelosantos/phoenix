defmodule Phoenix.Router.NamedRoutingTest do
  use ExUnit.Case, async: true
  use RouterHelper

  defmodule Router do
    use Phoenix.Router

    get "/posts/top", PostController, :top, as: :top
    get "/posts/:id", PostController, :show
    get "/posts/file/*file", PostController, :file
    get "/posts/skip", PostController, :skip, as: nil

    resources "/users", UserController do
      resources "/comments", CommentController do
        resources "/files", FileController
      end
    end

    resources "/files", FileController

    scope path: "/admin", alias: Admin do
      resources "/messages", MessageController
    end

    scope path: "/admin/new", alias: Admin, as: "admin" do
      resources "/messages", MessageController
    end
  end

  alias Router.Helpers

  Application.put_env(:phoenix, Router,
    port: 1337, proxy_port: 80, host: "example.com", ssl: false)

  test "top-level named route" do
    assert Helpers.post_path(:show, 5) == "/posts/5"
    assert Helpers.post_path(:show, 5, []) == "/posts/5"

    assert Helpers.post_path(:file, ["foo", "bar"]) == "/posts/file/foo/bar"
    assert Helpers.post_path(:file, ["foo", "bar"], []) == "/posts/file/foo/bar"

    assert Helpers.top_path(:top) == "/posts/top"
    assert Helpers.top_path(:top, id: 5) == "/posts/top?id=5"

    assert_raise UndefinedFunctionError, fn ->
      Helpers.post_path(:skip)
    end
  end

  test "resources generates named routes for :index, :edit, :show, :new" do
    assert Helpers.user_path(:index, []) == "/users"
    assert Helpers.user_path(:index) == "/users"
    assert Helpers.user_path(:edit, 123, []) == "/users/123/edit"
    assert Helpers.user_path(:edit, 123) == "/users/123/edit"
    assert Helpers.user_path(:show, 123, []) == "/users/123"
    assert Helpers.user_path(:show, 123) == "/users/123"
    assert Helpers.user_path(:new, []) == "/users/new"
    assert Helpers.user_path(:new) == "/users/new"
  end

  test "resources generates named routes for :create, :update, :delete" do
    assert Helpers.message_path(:create, []) == "/admin/messages"
    assert Helpers.message_path(:create) == "/admin/messages"

    assert Helpers.message_path(:update, 1, []) == "/admin/messages/1"
    assert Helpers.message_path(:update, 1) == "/admin/messages/1"

    assert Helpers.message_path(:destroy, 1, []) == "/admin/messages/1"
    assert Helpers.message_path(:destroy, 1) == "/admin/messages/1"
  end

  test "1-Level nested resources generates nested named routes for :index, :edit, :show, :new" do
    assert Helpers.user_comment_path(:index, 99, []) == "/users/99/comments"
    assert Helpers.user_comment_path(:index, 99) == "/users/99/comments"
    assert Helpers.user_comment_path(:edit, 88, 2, []) == "/users/88/comments/2/edit"
    assert Helpers.user_comment_path(:edit, 88, 2) == "/users/88/comments/2/edit"
    assert Helpers.user_comment_path(:show, 123, 2, []) == "/users/123/comments/2"
    assert Helpers.user_comment_path(:show, 123, 2) == "/users/123/comments/2"
    assert Helpers.user_comment_path(:new, 88, []) == "/users/88/comments/new"
    assert Helpers.user_comment_path(:new, 88) == "/users/88/comments/new"
  end

  test "2-Level nested resources generates nested named routes for :index, :edit, :show, :new" do
    assert Helpers.user_comment_file_path(:index, 99, 1, []) ==
      "/users/99/comments/1/files"
    assert Helpers.user_comment_file_path(:index, 99, 1) ==
      "/users/99/comments/1/files"

    assert Helpers.user_comment_file_path(:edit, 88, 1, 2, []) ==
      "/users/88/comments/1/files/2/edit"
    assert Helpers.user_comment_file_path(:edit, 88, 1, 2) ==
      "/users/88/comments/1/files/2/edit"

    assert Helpers.user_comment_file_path(:show, 123, 1, 2, []) ==
      "/users/123/comments/1/files/2"
    assert Helpers.user_comment_file_path(:show, 123, 1, 2) ==
      "/users/123/comments/1/files/2"

    assert Helpers.user_comment_file_path(:new, 88, 1, []) ==
      "/users/88/comments/1/files/new"
    assert Helpers.user_comment_file_path(:new, 88, 1) ==
      "/users/88/comments/1/files/new"
  end

  test "resources without block generates named routes for :index, :edit, :show, :new" do
    assert Helpers.file_path(:index, []) == "/files"
    assert Helpers.file_path(:index) == "/files"
    assert Helpers.file_path(:edit, 123, []) == "/files/123/edit"
    assert Helpers.file_path(:edit, 123) == "/files/123/edit"
    assert Helpers.file_path(:show, 123, []) == "/files/123"
    assert Helpers.file_path(:show, 123) == "/files/123"
    assert Helpers.file_path(:new, []) == "/files/new"
    assert Helpers.file_path(:new) == "/files/new"
  end

  test "scoped route helpers generated named routes with :path, and :alias options" do
    assert Helpers.message_path(:index, []) == "/admin/messages"
    assert Helpers.message_path(:index) == "/admin/messages"
    assert Helpers.message_path(:show, 1, []) == "/admin/messages/1"
    assert Helpers.message_path(:show, 1) == "/admin/messages/1"
  end

  test "scoped route helpers generated named routes with :path, :alias, and :helper options" do
    assert Helpers.admin_message_path(:index, []) == "/admin/new/messages"
    assert Helpers.admin_message_path(:index) == "/admin/new/messages"
    assert Helpers.admin_message_path(:show, 1, []) == "/admin/new/messages/1"
    assert Helpers.admin_message_path(:show, 1) == "/admin/new/messages/1"
  end

  test "helpers module generates a url helper" do
    assert Helpers.url("/foo/bar") == "http://example.com/foo/bar"
  end
end
