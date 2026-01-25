defmodule Droodotfoo.Fileverse.DSheet.Validation do
  @moduledoc """
  Validation helpers for dSheet operations.
  Consolidates repeated wallet validation pattern.
  """

  @doc """
  Validate wallet address is present and execute function if valid.
  Returns {:error, :wallet_required} if wallet is nil.

  ## Examples

      iex> with_wallet("0x123", fn wallet -> {:ok, wallet} end)
      {:ok, "0x123"}

      iex> with_wallet(nil, fn _wallet -> {:ok, :data} end)
      {:error, :wallet_required}
  """
  def with_wallet(nil, _fun), do: {:error, :wallet_required}
  def with_wallet(wallet_address, fun), do: fun.(wallet_address)

  @doc """
  Validate sheet ID format.
  """
  def valid_sheet_id?("sheet_" <> _rest), do: true
  def valid_sheet_id?(_), do: false
end
