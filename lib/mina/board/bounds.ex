defmodule Mina.Board.Bounds do
  @moduledoc false

  defguardp in_bot_x?(bounds, position) when elem(position, 0) >= elem(elem(bounds, 0), 0)
  defguardp in_top_x?(bounds, position) when elem(position, 0) <= elem(elem(bounds, 1), 0)
  defguardp in_bot_y?(bounds, position) when elem(position, 1) >= elem(elem(bounds, 0), 1)
  defguardp in_top_y?(bounds, position) when elem(position, 1) <= elem(elem(bounds, 1), 1)

  defguard in_bounds?(bounds, position)
           when is_nil(bounds) or
                  (in_bot_x?(bounds, position) and
                     in_top_x?(bounds, position) and
                     in_bot_y?(bounds, position) and
                     in_top_y?(bounds, position))
end
