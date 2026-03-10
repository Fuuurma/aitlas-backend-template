defmodule Aitlas.CreditsTest do
  use Aitlas.DataCase, async: false

  alias Aitlas.Credits

  describe "get_balance/1" do
    test "returns 0 for user with no entries" do
      user = insert(:user)
      assert Credits.get_balance(user.id) == 0
    end

    test "returns the balance from the most recent entry" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 100, balance: 100)
      insert(:ledger_entry, user_id: user.id, amount: -50, balance: 50)

      assert Credits.get_balance(user.id) == 50
    end
  end

  describe "has_credits?/2" do
    test "returns true when user has enough credits" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 100, balance: 100)

      assert Credits.has_credits?(user.id, 50) == true
      assert Credits.has_credits?(user.id, 100) == true
    end

    test "returns false when user has insufficient credits" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 50, balance: 50)

      assert Credits.has_credits?(user.id, 100) == false
    end

    test "returns false for user with no entries" do
      user = insert(:user)
      assert Credits.has_credits?(user.id, 1) == false
    end
  end

  describe "grant/4" do
    test "creates a new entry with correct balance" do
      user = insert(:user)

      assert {:ok, _entry} = Credits.grant(user.id, 100, "purchase")

      assert Credits.get_balance(user.id) == 100
    end

    test "adds to existing balance" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 50, balance: 50)

      assert {:ok, _entry} = Credits.grant(user.id, 25, "bonus")

      assert Credits.get_balance(user.id) == 75
    end
  end

  describe "deduct/4" do
    test "deducts credits from user balance" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 100, balance: 100)

      assert {:ok, _entry} = Credits.deduct(user.id, 30, "tool_call", "task_123")

      assert Credits.get_balance(user.id) == 70
    end
  end

  describe "reserve/3" do
    test "reserves credits when user has enough" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 100, balance: 100)

      assert {:ok, _entry} = Credits.reserve(user.id, 50, "task_123")

      assert Credits.get_balance(user.id) == 50
    end

    test "returns error when insufficient credits" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 30, balance: 30)

      assert {:error, :insufficient_credits} = Credits.reserve(user.id, 50, "task_123")

      assert Credits.get_balance(user.id) == 30
    end
  end

  describe "refund/3" do
    test "refunds credits to user" do
      user = insert(:user)
      insert(:ledger_entry, user_id: user.id, amount: 50, balance: 50)

      assert {:ok, _entry} = Credits.refund(user.id, 25, "task_123")

      assert Credits.get_balance(user.id) == 75
    end
  end
end
