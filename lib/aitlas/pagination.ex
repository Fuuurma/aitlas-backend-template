# lib/aitlas/pagination.ex
defmodule Aitlas.Pagination do
  @moduledoc """
  Pagination utilities for Ecto queries.

  Provides cursor-based and offset-based pagination with
  metadata for API responses.

  ## Offset-based Pagination

      # In controller
      params = Pagination.Params.from_map(%{"page" => 1, "limit" => 20})
      {items, meta} = Pagination.paginate(query, params)

      # Response
      json(conn, Response.success(items, meta))

  ## Cursor-based Pagination (for large datasets)

      # In controller
      params = Pagination.CursorParams.from_map(params)
      {items, cursor} = Pagination.cursor_paginate(query, params)

      # Response
      json(conn, Response.success(items, %{cursor: cursor}))

  ## Metadata

      %{
        page: 1,
        per_page: 20,
        total: 100,
        total_pages: 5,
        has_next: true,
        has_prev: false
      }
  """

  import Ecto.Query

  # ─── Offset-based Pagination ───────────────────────────────────

  defmodule Params do
    @moduledoc "Pagination parameters"
    defstruct [:page, :limit, :sort, :order]

    @default_page 1
    @default_limit 20
    @max_limit 100

    def from_map(params) when is_map(params) do
      page = parse_int(params["page"], @default_page) |> max(1)
      limit = parse_int(params["limit"], @default_limit) |> min(@max_limit) |> max(1)
      sort = params["sort"]
      order = parse_order(params["order"])

      %__MODULE__{page: page, limit: limit, sort: sort, order: order}
    end

    defp parse_int(nil, default), do: default
    defp parse_int(value, default) when is_binary(value) do
      case Integer.parse(value) do
        {int, _} -> int
        _ -> default
      end
    end
    defp parse_int(value, _) when is_integer(value), do: value

    defp parse_order("desc"), do: :desc
    defp parse_order(_), do: :asc

    def offset(%__MODULE__{page: page, limit: limit}), do: (page - 1) * limit
  end

  @doc """
  Paginate an Ecto query.
  Returns {items, metadata}.
  """
  def paginate(query, %Params{} = params) do
    total = count_total(query)

    items =
      query
      |> apply_sort(params)
      |> limit(^params.limit)
      |> offset(^Params.offset(params))
      |> Repo.all()

    meta = build_meta(params, total)

    {items, meta}
  end

  defp count_total(query) do
    query
    |> exclude(:order_by)
    |> exclude(:preload)
    |> exclude(:select)
    |> select([_], count())
    |> Repo.one()
  end

  defp apply_sort(query, %Params{sort: nil}), do: query
  defp apply_sort(query, %Params{sort: field, order: order}) when is_atom(field) do
    order_by(query, [{^order, ^field}])
  end
  defp apply_sort(query, %Params{sort: field, order: order}) when is_binary(field) do
    field_atom = String.to_atom(field)
    order_by(query, [{^order, ^field_atom}])
  rescue
    ArgumentError -> query
  end

  defp build_meta(params, total) do
    total_pages = ceil(total / params.limit)

    %{
      page: params.page,
      per_page: params.limit,
      total: total,
      total_pages: total_pages,
      has_next: params.page < total_pages,
      has_prev: params.page > 1
    }
  end

  # ─── Cursor-based Pagination ───────────────────────────────────

  defmodule CursorParams do
    @moduledoc "Cursor pagination parameters"
    defstruct [:cursor, :limit, :direction]

    @default_limit 20
    @max_limit 100

    def from_map(params) when is_map(params) do
      limit = parse_int(params["limit"], @default_limit) |> min(@max_limit) |> max(1)

      %__MODULE__{
        cursor: params["cursor"],
        limit: limit,
        direction: parse_direction(params["direction"])
      }
    end

    defp parse_int(nil, default), do: default
    defp parse_int(value, default) when is_binary(value) do
      case Integer.parse(value) do
        {int, _} -> int
        _ -> default
      end
    end
    defp parse_int(value, _) when is_integer(value), do: value

    defp parse_direction("prev"), do: :prev
    defp parse_direction(_), do: :next
  end

  @doc """
  Cursor-based pagination for large datasets.
  Returns {items, cursor_info}.
  """
  def cursor_paginate(query, %CursorParams{} = params, opts \\ []) do
    cursor_field = Keyword.get(opts, :cursor_field, :id)
    limit = params.limit + 1 # Fetch one extra to check for more

    items =
      case {params.cursor, params.direction} do
        {nil, _} ->
          query
          |> limit(^limit)
          |> Repo.all()

        {cursor, :next} ->
          query
          |> where([x], field(x, ^cursor_field) > ^cursor)
          |> limit(^limit)
          |> Repo.all()

        {cursor, :prev} ->
          query
          |> where([x], field(x, ^cursor_field) < ^cursor)
          |> order_by([x], desc: ^cursor_field)
          |> limit(^limit)
          |> Repo.all()
          |> Enum.reverse()
      end

    {items, cursor_info} = extract_cursor_info(items, params.limit, cursor_field)

    {items, cursor_info}
  end

  defp extract_cursor_info(items, limit, cursor_field) do
    has_more = length(items) > limit
    items = Enum.take(items, limit)

    cursor_info = %{
      has_next: has_more,
      has_prev: false, # Would need previous cursor to determine
      next_cursor: get_cursor(items, cursor_field, :last),
      prev_cursor: get_cursor(items, cursor_field, :first)
    }

    {items, cursor_info}
  end

  defp get_cursor([], _, _), do: nil
  defp get_cursor(items, field, :first) do
    first = List.first(items)
    Map.get(first, field)
  end
  defp get_cursor(items, field, :last) do
    last = List.last(items)
    Map.get(last, field)
  end
end