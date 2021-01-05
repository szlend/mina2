defmodule Mina.AppCase do
  @moduledoc """
  This module defines the setup for tests requiring
  work with multiple nodes.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Mina.DataCase, async: false
    end
  end

  setup do
    {:ok, _app} = Application.ensure_all_started(:mina)
    on_exit(fn -> Application.stop(:mina) end)
  end
end
