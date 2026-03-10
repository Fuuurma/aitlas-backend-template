defmodule Aitlas.Factory do
  @moduledoc """
  Test factory using ExMachina for generating test data.
  """

  use ExMachina.Ecto, repo: Aitlas.Repo

  def user_factory do
    %Aitlas.Accounts.User{
      id: sequence(:user_id, &"user_#{&1}"),
      name: sequence(:name, &"User #{&1}"),
      email: sequence(:email, &"user#{&1}@example.com"),
      email_verified: true
    }
  end

  def session_factory do
    %Aitlas.Accounts.Session{
      id: sequence(:session_id, &"session_#{&1}"),
      token: sequence(:token, &"token_#{&1}"),
      user_id: insert(:user).id,
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
    }
  end

  def ledger_entry_factory do
    %Aitlas.Credits.LedgerEntry{
      user_id: insert(:user).id,
      amount: 100,
      balance: 100,
      reason: "test_grant"
    }
  end
end
