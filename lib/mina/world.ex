defmodule Mina.World do
  @moduledoc """
  Minesweeper world game logic.
  """

  alias __MODULE__

  @min_difficulty 0
  @max_difficulty 100
  @partition_size 50

  @type t :: %World{seed: seed, difficulty: difficulty, partition_size: pos_integer}
  defstruct [:seed, :difficulty, :partition_size]

  @type id :: {seed, difficulty, pos_integer}
  @type seed :: String.t()
  @type difficulty :: non_neg_integer
  @type position :: {integer, integer}
  @type tile :: :mine | {:proximity, 0..8}
  @type bounds :: {position, position}
  @type reveals :: %{position => tile}

  @type build_opt :: {:partition_size, pos_integer}
  @type reveal_opt :: {:bounds, :infinity | bounds} | {:reveals, reveals}

  @doc """
  Builds a new world with the given `seed` and `difficulty`.

  ## Options

  The accepted options are:

  * `:partition_size` - the width of each world partition.
  """
  @spec build(seed, difficulty, [build_opt]) :: t
  def build(seed, difficulty, opts \\ [])
      when difficulty >= @min_difficulty and difficulty <= @max_difficulty do
    size = Keyword.get(opts, :partition_size, @partition_size)
    %World{seed: seed, difficulty: difficulty, partition_size: size}
  end

  @doc """
  Returns the world id tuple.
  """
  @spec id(t) :: id
  def id(world) do
    {world.seed, world.difficulty, world.partition_size}
  end

  @doc """
  Check whether a mine is present on the `world` at a given `position`.
  """
  @spec mine_at?(t, position) :: boolean
  def mine_at?(world, position) do
    :erlang.phash2({world.seed, position}, @max_difficulty) < world.difficulty
  end

  @doc """
  Returns the type of tile and a list of adjacent tiles that need to be revealed
  on the `world` at a given `position`. A tile can either be a `:mine` or
  a `{:proximity, rank}`.
  """
  @spec reveal_at(t, position) :: {tile, [position]}
  def reveal_at(world, position) do
    if mine_at?(world, position) do
      {:mine, []}
    else
      adjacent_positions = adjacent_positions(position)

      case Enum.count(adjacent_positions, &mine_at?(world, &1)) do
        0 -> {{:proximity, 0}, adjacent_positions}
        n -> {{:proximity, n}, []}
      end
    end
  end

  @doc """
  Reveals tiles on the `world`, starting from `position`. Returns the reveals (`position => tile`).

  ## Options

  The accepted options are:

  * `:bounds` - the inclusive bounds (bottom-left, top-right) to restrict revealing to
                (e.g, `{{0, 0}, {5, 5}}`). Defaults to `:infinity`.
  * `:reveals` - a map of existing reveals which to ignore in new reveals.
  """
  @spec reveal(t, position, [reveal_opt]) :: reveals
  def reveal(world, position, opts \\ []) do
    bounds = Keyword.get(opts, :bounds, :infinity)
    reveals = Keyword.get(opts, :reveals, %{})
    Map.new(do_reveal(world, [position], bounds, reveals))
  end

  # stop revealing when out of positions
  defp do_reveal(_world, [], _bounds, _reveals), do: []

  # skip revealing out of bound positions
  defp do_reveal(w, [{x, y} | positions], {{bot_x, bot_y}, {top_x, top_y}} = b, r)
       when x < bot_x or y < bot_y or x > top_x or y > top_y do
    do_reveal(w, positions, b, r)
  end

  # skip revealing already revealed positions
  defp do_reveal(w, [position | positions], b, reveals) when is_map_key(reveals, position) do
    do_reveal(w, positions, b, reveals)
  end

  defp do_reveal(world, [position | positions], bounds, reveals) do
    {tile, adjacent_positions} = reveal_at(world, position)
    reveals = Map.put(reveals, position, tile)
    [{position, tile} | do_reveal(world, adjacent_positions ++ positions, bounds, reveals)]
  end

  defp adjacent_positions({x, y}) do
    [
      {x - 1, y + 1},
      {x + 0, y + 1},
      {x + 1, y + 1},
      {x - 1, y + 0},
      {x + 1, y + 0},
      {x - 1, y - 1},
      {x + 0, y - 1},
      {x + 1, y - 1}
    ]
  end
end
