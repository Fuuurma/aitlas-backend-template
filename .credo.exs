# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: [
        # Built-in Credo checks
        {Credo.Check.Consistency.TabsOrSpaces, []},

        # ex_slop checks - AI-generated code slop
        # Warnings
        {ExSlop.Check.Warning.BlanketRescue, []},
        {ExSlop.Check.Warning.RescueWithoutReraise, []},
        {ExSlop.Check.Warning.RepoAllThenFilter, []},
        {ExSlop.Check.Warning.QueryInEnumMap, []},
        {ExSlop.Check.Warning.GenserverAsKvStore, []},

        # Refactors
        {ExSlop.Check.Refactor.FilterNil, []},
        {ExSlop.Check.Refactor.RejectNil, []},
        {ExSlop.Check.Refactor.ReduceAsMap, []},
        {ExSlop.Check.Refactor.MapIntoLiteral, []},
        {ExSlop.Check.Refactor.IdentityPassthrough, []},
        {ExSlop.Check.Refactor.IdentityMap, []},
        {ExSlop.Check.Refactor.CaseTrueFalse, []},
        {ExSlop.Check.Refactor.TryRescueWithSafeAlternative, []},
        {ExSlop.Check.Refactor.WithIdentityElse, []},
        {ExSlop.Check.Refactor.WithIdentityDo, []},
        {ExSlop.Check.Refactor.SortThenReverse, []},
        {ExSlop.Check.Refactor.StringConcatInReduce, []},

        # Readability
        {ExSlop.Check.Readability.NarratorDoc, []},
        {ExSlop.Check.Readability.DocFalseOnPublicFunction, []},
        {ExSlop.Check.Readability.BoilerplateDocParams, []},
        {ExSlop.Check.Readability.ObviousComment, []},
        {ExSlop.Check.Readability.StepComment, []},
        {ExSlop.Check.Readability.NarratorComment, []}
      ]
    }
  ]
}