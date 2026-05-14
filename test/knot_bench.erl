-module(knot_bench).

-compile([nowarn_missing_spec, nowarn_missing_spec_all]).

-export([run/0]).

-define(N_MICRO,       10_000_000).
-define(N_RUNS,        5).            % median over N_RUNS
-define(BOUND,         254).
-define(CONCURRENCIES, [1, 8, 32, 128]).

%% Macro: hot loop expanded to avoid lists:seq/lists:foreach allocations.
%% The arg is the call expression itself, evaluated N times.

run() ->
    _ = application:ensure_all_started(knot),
    _ = application:ensure_all_started(granderl),
    io:format("~n=== microbench (single proc, ~p iter, median of ~p runs) ===~n",
              [?N_MICRO, ?N_RUNS]),
    micro_run("rand:uniform/1",     fun() -> rand:uniform(?BOUND) end),
    micro_run("granderl:uniform/1", fun() -> granderl:uniform(?BOUND) end),
    micro_run("knot:uniform/1",    fun() -> knot:uniform(?BOUND) end),
    io:format("~n=== concurrent bench (~p iter total, median of ~p runs) ===~n",
              [?N_MICRO, ?N_RUNS]),
    [run_concurrent(C) || C <- ?CONCURRENCIES],
    ok.

run_concurrent(Concurrency) ->
    io:format("~n-- concurrency=~p --~n", [Concurrency]),
    concurrent_run("rand",     Concurrency, fun() -> rand:uniform(?BOUND) end),
    concurrent_run("granderl", Concurrency, fun() -> granderl:uniform(?BOUND) end),
    concurrent_run("knot",    Concurrency, fun() -> knot:uniform(?BOUND) end),
    ok.

%%--- microbench: median over N_RUNS ---------------------------------------

micro_run(Name, Fun) ->
    %% Warmup
    spin(?N_MICRO div 10, Fun),
    %% Measure
    Times = [time_one(?N_MICRO, Fun) || _ <- lists:seq(1, ?N_RUNS)],
    Median = median(Times),
    Ns = Median / ?N_MICRO,
    OpsPerSec = round(?N_MICRO * 1_000_000_000 / Median),
    io:format("  ~-22s ~7.1f ns/op   ~12B ops/sec~n",
              [Name, Ns, OpsPerSec]).

time_one(N, Fun) ->
    T0 = erlang:monotonic_time(nanosecond),
    spin(N, Fun),
    T1 = erlang:monotonic_time(nanosecond),
    T1 - T0.

%% Tight loop that's not list-allocating.
spin(0, _Fun) -> ok;
spin(N, Fun)  -> Fun(), spin(N - 1, Fun).

median(L) ->
    Sorted = lists:sort(L),
    lists:nth(length(L) div 2 + 1, Sorted).

%%--- concurrent bench: median over N_RUNS ---------------------------------

concurrent_run(Name, Concurrency, Fun) ->
    Times = [time_concurrent(Concurrency, Fun) || _ <- lists:seq(1, ?N_RUNS)],
    Median = median(Times),
    Ns = Median / ?N_MICRO,
    OpsPerSec = round(?N_MICRO * 1_000_000_000 / Median),
    io:format("  ~-10s ~7.1f ns/op   ~12B ops/sec~n",
              [Name, Ns, OpsPerSec]).

time_concurrent(Concurrency, Fun) ->
    PerWorker = ?N_MICRO div Concurrency,
    Parent = self(),
    T0 = erlang:monotonic_time(nanosecond),
    Pids = [spawn_link(fun() ->
                          spin(PerWorker, Fun),
                          Parent ! {self(), done}
                      end) || _ <- lists:seq(1, Concurrency)],
    [receive {Pid, done} -> ok end || Pid <- Pids],
    T1 = erlang:monotonic_time(nanosecond),
    T1 - T0.
