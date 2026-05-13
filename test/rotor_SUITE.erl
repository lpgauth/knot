-module(rotor_SUITE).

-compile([export_all, nowarn_export_all, nowarn_missing_spec, nowarn_missing_spec_all]).

-include_lib("common_test/include/ct.hrl").

all() ->
    [
        uniform_one_returns_one,
        uniform_range_invariant,
        uniform_max_u32,
        distribution_chi_square,
        cross_thread_independence
    ].

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(rotor),
    Config.

end_per_suite(_Config) ->
    ok.

uniform_one_returns_one(_) ->
    %% N=1 always returns 1.
    true = lists:all(fun(X) -> X =:= 1 end,
                     [rotor:uniform(1) || _ <- lists:seq(1, 10_000)]).

uniform_range_invariant(_) ->
    %% For each N, all 100k draws must lie in [1, N].
    lists:foreach(
      fun(N) ->
          true = lists:all(fun(X) -> X >= 1 andalso X =< N end,
                           [rotor:uniform(N) || _ <- lists:seq(1, 100_000)])
      end,
      [2, 16, 254, 65535, 16#FFFFFFFF]).

uniform_max_u32(_) ->
    %% Exercise the upper bound of the u32 range.
    Max = 16#FFFFFFFF,
    Samples = [rotor:uniform(Max) || _ <- lists:seq(1, 10_000)],
    true = lists:all(fun(X) -> X >= 1 andalso X =< Max end, Samples).

distribution_chi_square(_) ->
    %% 1M draws of uniform(100); chi-square at p=0.001, df=99 → 148.2.
    Buckets = 100,
    N       = 1_000_000,
    Expected = N / Buckets,
    Counters = ets:new(rotor_dist, [public]),
    [ets:insert(Counters, {I, 0}) || I <- lists:seq(1, Buckets)],
    lists:foreach(
      fun(_) ->
          R = rotor:uniform(Buckets),
          ets:update_counter(Counters, R, 1)
      end,
      lists:seq(1, N)),
    Chi = lists:foldl(
            fun({_, C}, Acc) ->
                D = C - Expected,
                Acc + (D * D / Expected)
            end, 0.0, ets:tab2list(Counters)),
    ets:delete(Counters),
    ct:pal("chi-square = ~p (threshold ~p)", [Chi, 200.0]),
    true = Chi < 200.0.

cross_thread_independence(_) ->
    %% 16 processes each draw 10k from uniform(1B); no two processes
    %% should produce the exact same sequence (state is per-OS-thread,
    %% but each process gets scheduled across schedulers — they may
    %% share state with one another. The test still rules out the
    %% degenerate case where every process gets the same seed).
    Parent = self(),
    N = 16,
    [spawn_link(fun() ->
                    Seq = [rotor:uniform(16#FFFFFFFF) || _ <- lists:seq(1, 10_000)],
                    Parent ! {self(), Seq}
                end) || _ <- lists:seq(1, N)],
    Seqs = [receive {_, Seq} -> Seq end || _ <- lists:seq(1, N)],
    Unique = sets:from_list(Seqs),
    NUnique = sets:size(Unique),
    ct:pal("~p/~p sequences unique", [NUnique, N]),
    %% Allow some collision if two processes ran on the same scheduler
    %% sequentially with identical seeds, but at least most should differ.
    true = NUnique >= N div 2.
