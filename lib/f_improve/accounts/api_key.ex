defmodule FImprove.Accounts.ApiKey do
  @moduledoc """
  User's API key for BYOK (Bring Your Own Key).
  
  Keys are encrypted at rest using AES-256-GCM.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  alias FImprove.Crypto
  
  schema "api_keys" do
    field :user_id, :string
    field :provider, :string  # openai, anthropic, etc.
    field :encrypted_key, :string
    field :key_preview, :string  # e.g., "sk-...abc123"
    field :is_active, :boolean, default: true
    
    timestamps()
  end
  
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:user_id, :provider, :encrypted_key, :key_preview, :is_active])
    |> validate_required([:user_id, :provider, :encrypted_key])
    |> validate_inclusion(:provider, ~w(openai anthropic google))
  end
  
  @doc """
  Encrypt and store an API key.
  """
  def create(user_id, provider, plain_key) do
    encrypted = Crypto.encrypt(plain_key)
    preview = create_preview(plain_key)
    
    changeset(%__MODULE__{}, %{
      user_id: user_id,
      provider: provider,
      encrypted_key: encrypted,
      key_preview: preview
    })
  end
  
  @doc """
  Decrypt and return the plain API key.
  """
  def decrypt(api_key) do
    Crypto.decrypt(api_key.encrypted_key)
  end
  
  defp create_preview(plain_key) do
    # Show first 7 and last 6 chars
    if String.length(plain_key) > 13 do
      String.slice(plain_key, 0, 7) <> "..." <> String.slice(plain_key, -6, 6)
    else
      String.slice(plain_key, 0, 3) <> "..."
    end
  end
end