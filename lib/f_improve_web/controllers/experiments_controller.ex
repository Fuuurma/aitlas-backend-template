defmodule FImproveWeb.ExperimentsController do
  @moduledoc """
  Experiments API controller.
  """
  
  use FImproveWeb, :controller
  
  alias FImprove.Experiments
  
  def index(conn, %{"job_id" => job_id}) do
    experiments = Experiments.list_experiments(job_id)
    json(conn, %{experiments: experiments})
  end
  
  def tsv(conn, %{"job_id" => job_id}) do
    experiments = Experiments.list_experiments(job_id)
    tsv = Experiments.format_tsv(experiments)
    
    conn
    |> put_resp_content_type("text/tab-separated-values")
    |> put_resp_header("content-disposition", "attachment; filename=\"experiments.tsv\"")
    |> send_resp(200, tsv)
  end
end