defmodule Aitlas.DataCase do
  @moduledoc """
  Test case template for tests requiring database access.

  Enables SQL sandbox for automatic transaction rollback between tests.
  Use `use Aitlas.DataCase, async: true` for database tests.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Aitlas.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Aitlas.DataCase
      import Aitlas.Factory
    end
  end

  setup tags do
    Aitlas.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Aitlas.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  Transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
