defmodule Mina.WorldTest do
  use Mina.DataCase, async: true

  alias Mina.World

  setup do
    #  -5   -4   -3   -2   -1    0    1    2    3    4    5
    # ["1", "2", "1", "2", "2", "2", "1", ".", "1", "x", "x"],  5
    # ["x", "3", "x", "2", "x", "1", ".", ".", "1", "2", "3"],  4
    # ["x", "3", "2", "3", "2", "1", ".", ".", ".", ".", "."],  3
    # ["2", "2", "2", "x", "2", "1", "1", ".", ".", ".", "."],  2
    # ["1", "1", "x", "3", "3", "x", "2", "1", ".", "1", "1"],  1
    # ["1", "1", "3", "x", "3", "2", "x", "2", "1", "2", "x"],  0
    # [".", ".", "2", "x", "2", "1", "1", "2", "x", "2", "1"], -1
    # [".", ".", "1", "2", "2", "1", ".", "1", "1", "1", "."], -2
    # [".", ".", ".", "1", "x", "1", ".", "1", "1", "1", "1"], -3
    # ["1", "1", "2", "2", "2", "1", ".", "1", "x", "2", "3"], -4
    # ["1", "x", "2", "x", "2", "1", "1", "1", "2", "x", "3"]  -5

    [world: %World{seed: "test", difficulty: 11}]
  end

  describe "build/2" do
    test "builds a new world with min difficulty" do
      assert %World{seed: "test", difficulty: 0} = World.build("test", 0)
    end

    test "builds a new world with difficulty" do
      assert %World{seed: "test", difficulty: 50} = World.build("test", 50)
    end

    test "builds a new world with max difficulty" do
      assert %World{seed: "test", difficulty: 100} = World.build("test", 100)
    end

    test "builds a new world with partition size" do
      assert %World{partition_size: 5} = World.build("test", 10, partition_size: 5)
    end

    test "raises an error with invalid difficulty - negative" do
      assert_raise FunctionClauseError, fn -> World.build("test", -1) end
    end

    test "raises an error with invalid difficulty - positive" do
      assert_raise FunctionClauseError, fn -> World.build("test", 101) end
    end
  end

  describe "id/1" do
    setup do
      [world: %World{seed: "test", difficulty: 11, partition_size: 5}]
    end

    test "returns the correct id", %{world: world} do
      assert World.id(world) == {"test", 11, 5}
    end
  end

  describe "key/1" do
    setup do
      [world: %World{seed: "test", difficulty: 11, partition_size: 5}]
    end

    test "returns the correct id", %{world: world} do
      assert World.key(world) == "test-11-5"
    end
  end

  describe "mine_at?/2" do
    test "returns true when a mine is present", %{world: world} do
      assert World.mine_at?(world, {0, 1}) == true
    end

    test "returns false when a mine is not present", %{world: world} do
      assert World.mine_at?(world, {0, 0}) == false
    end
  end

  describe "reveal_at/2" do
    test "returns a mine when a mine is present", %{world: world} do
      assert World.reveal_at(world, {0, 1}) == {:mine, []}
    end

    test "returns a proximity level when a mine is not present", %{world: world} do
      assert World.reveal_at(world, {0, 0}) == {{:proximity, 2}, []}
    end

    test "returns a proximity level 0 with adjacent mines when no mines around", %{world: world} do
      assert World.reveal_at(world, {1, -2}) ==
               {{:proximity, 0},
                [{0, -1}, {1, -1}, {2, -1}, {0, -2}, {2, -2}, {0, -3}, {1, -3}, {2, -3}]}
    end
  end

  describe "reveal/2" do
    test "reveals a mine", %{world: world} do
      assert World.reveal(world, {0, 1}) == %{{0, 1} => :mine}
    end

    test "reveals a proximate tile", %{world: world} do
      assert World.reveal(world, {0, 0}) == %{{0, 0} => {:proximity, 2}}
    end

    test "reveals an empty tile", %{world: world} do
      assert World.reveal(world, {1, -2}) == %{
               {0, -5} => {:proximity, 1},
               {0, -4} => {:proximity, 1},
               {0, -3} => {:proximity, 1},
               {0, -2} => {:proximity, 1},
               {0, -1} => {:proximity, 1},
               {1, -5} => {:proximity, 1},
               {1, -4} => {:proximity, 0},
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -5} => {:proximity, 1},
               {2, -4} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end

    test "reveals only tiles within bounds", %{world: world} do
      assert World.reveal(world, {1, -2}, bounds: {{0, -3}, {2, -1}}) == %{
               {0, -3} => {:proximity, 1},
               {0, -2} => {:proximity, 1},
               {0, -1} => {:proximity, 1},
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end

    test "does not reveal tiles outside bounds", %{world: world} do
      assert World.reveal(world, {3, 3}, bounds: {{-2, -2}, {2, 2}}) == %{}
    end

    test "does not reveal previous reveals", %{world: world} do
      bounds = {{0, -3}, {2, -1}}

      reveals = %{
        {0, -3} => {:proximity, 1},
        {0, -2} => {:proximity, 1},
        {0, -1} => {:proximity, 1}
      }

      assert World.reveal(world, {1, -2}, bounds: bounds, reveals: reveals) == %{
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end
  end

  describe "flag/2" do
    test "flags a mine", %{world: world} do
      assert World.flag(world, {0, 1}) == %{{0, 1} => :flag}
    end

    test "reveals a proximate tile", %{world: world} do
      assert World.flag(world, {0, 0}) == %{{0, 0} => {:proximity, 2}}
    end

    test "reveals an empty tile", %{world: world} do
      assert World.flag(world, {1, -2}) == %{
               {0, -5} => {:proximity, 1},
               {0, -4} => {:proximity, 1},
               {0, -3} => {:proximity, 1},
               {0, -2} => {:proximity, 1},
               {0, -1} => {:proximity, 1},
               {1, -5} => {:proximity, 1},
               {1, -4} => {:proximity, 0},
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -5} => {:proximity, 1},
               {2, -4} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end

    test "reveals only tiles within bounds", %{world: world} do
      assert World.flag(world, {1, -2}, bounds: {{0, -3}, {2, -1}}) == %{
               {0, -3} => {:proximity, 1},
               {0, -2} => {:proximity, 1},
               {0, -1} => {:proximity, 1},
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end

    test "does not reveal tiles outside bounds", %{world: world} do
      assert World.flag(world, {3, 3}, bounds: {{-2, -2}, {2, 2}}) == %{}
    end

    test "does not reveal previous reveals", %{world: world} do
      bounds = {{0, -3}, {2, -1}}

      reveals = %{
        {0, -3} => {:proximity, 1},
        {0, -2} => {:proximity, 1},
        {0, -1} => {:proximity, 1}
      }

      assert World.flag(world, {1, -2}, bounds: bounds, reveals: reveals) == %{
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end
  end
end
