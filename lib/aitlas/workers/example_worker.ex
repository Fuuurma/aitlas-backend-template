defmodule Aitlas.Workers.ExampleWorker do
  @moduledoc """
  Example Oban worker template.

  Copy this file as a starting point for new workers.
  Configure queue, max_attempts, and unique settings as needed.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => _user_id} = _args}) do
    :ok
  end
end
