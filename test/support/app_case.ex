defmodule Mina.AppCase do
  @moduledoc """
  This module defines the setup for tests requiring
  work with multiple nodes.
  """

  use ExUnit.CaseTemplate

  setup tags do
    if tags[:async], do: raise("AppCase cannot run in async mode")
    :ok = Application.stop(:mina)
    {:ok, _app} = Application.ensure_all_started(:mina)
    :ok
  end
end
