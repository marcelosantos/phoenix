defmodule Phoenix.Router.Route do
  # This module defines the Route struct that is used
  # throughout Phoenix's router.
  @moduledoc false

  alias Phoenix.Router.Route

  @doc """
  The Route struct. It stores:

    * :verb - the HTTP verb as an upcased string
    * :path - the normalized path as string
    * :segments - the route path as quoted segments
    * :binding - the route bindings
    * :controller - the controller module
    * :action - the action as an atom
    * :helper - the named of the helper as a string (may be nil)

  """
  defstruct [:verb, :path, :segments, :binding, :controller, :action, :helper]
  @type t :: %Route{}

  @doc """
  Receives the verb, path, controller, action and helper
  and returns a Route struct. The given path is processed
  and validated, raising an error in case of invalid paths.
  """
  @spec build(String.t, String.t, atom, atom, atom) :: t
  def build(verb, path, controller, action, helper)
      when is_binary(verb) and is_binary(path) and is_atom(controller) and
           is_atom(action) and (is_binary(helper) or is_nil(helper)) do
    {params, segments} = Plug.Router.Utils.build_match(path)

    binding = Enum.map(params, fn var ->
      {Atom.to_string(var), Macro.var(var, nil)}
    end)

    %Route{verb: verb, path: path, segments: segments, binding: binding,
           controller: controller, action: action, helper: helper}
  end

  @doc """
  Receives a route and returns the quoted definition for the
  helper function in case a helper name was given, simply returns
  nil otherwise.
  """
  @spec defhelper(t) :: Macro.t | nil
  def defhelper(%Route{helper: nil}), do: nil

  def defhelper(%Route{} = route) do
    helper = route.helper
    action = route.action

    {bins, vars} = :lists.unzip(route.binding)
    segs = optimize_segments(route.segments)

    quote line: -1 do
      def unquote(:"#{helper}_path")(unquote(action), unquote_splicing(vars)) do
        unquote(:"#{helper}_path")(unquote(action), unquote_splicing(vars), [])
      end

      def unquote(:"#{helper}_path")(unquote(action), unquote_splicing(vars), params) do
        Route.segments_to_path(unquote(segs), params, unquote(bins))
      end
    end
  end

  defp optimize_segments(segments) when is_list(segments),
    do: optimize_segments(segments, "")
  defp optimize_segments(segments),
    do: quote(do: "/" <> Enum.join(unquote(segments), "/"))

  defp optimize_segments([{:|, _, [h, t]}], acc),
    do: quote(do: unquote(optimize_segments([h], acc)) <> "/" <> Enum.join(unquote(t), "/"))
  defp optimize_segments([h|t], acc) when is_binary(h),
    do: optimize_segments(t, quote(do: unquote(acc) <> unquote("/" <> h)))
  defp optimize_segments([h|t], acc),
    do: optimize_segments(t, quote(do: unquote(acc) <> "/" <> to_string(unquote(h))))
  defp optimize_segments([], acc),
    do: acc

  @doc """
  Receives a list of segments and params for query string and
  returns a path as a string.

  This function is invoked by the definitions generated by the
  `defhelper/1` function.
  """
  @spec segments_to_path(binary, Dict.t, [binary]) :: binary
  def segments_to_path(segments, [], _reserved) do
    segments
  end

  def segments_to_path(segments, query, reserved) do
    case Plug.Conn.Query.encode Dict.drop(query, reserved) do
      "" -> segments
      o  -> segments <> "?" <> o
    end
  end
end
