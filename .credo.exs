%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: [
        # Disabled in Elixir 1.10
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false}
      ]
    }
  ]
}
