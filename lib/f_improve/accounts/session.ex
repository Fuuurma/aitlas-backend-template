defmodule FImprove.Accounts.Session do
  @moduledoc """
  Session schema for authentication.
  """
  
  use Ecto.Schema
  
  schema "sessions" do
    field :user_id, :string
    field :token, :string
    field :expires_at, :utc_datetime
    field :ip_address, :string
    field :user_agent, :string
    
    timestamps()
  end
end