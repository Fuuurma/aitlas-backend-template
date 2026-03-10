defmodule Aitlas.Workers.ExampleWorker do
  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => _user_id} = _args}) do
    # Your job logic here
    :ok
  end
end