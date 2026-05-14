%% @doc Fast non-cryptographic PRNG NIF (wyrand).
%%
%% Drop-in replacement for `granderl:uniform/1'. Per-OS-thread state via
%% `__thread', lazy-seeded from `getrandom'/`arc4random_buf' on first
%% use. Biased multiply-and-shift bounded output -- single multiply,
%% no rejection branch (modulo bias under 1e-7 for bounds up to 256, invisible
%% at typical workload scale).
%%
%% Use {@link knot:uniform/1} to draw a uniformly distributed integer
%% from `1..N'. For bounds > `4294967295' (2^32 - 1), the NIF rejects
%% with `badarg' -- the C-side argument is an unsigned 32-bit int.
-module(knot).

-on_load(init/0).

-export([uniform/1]).

-spec init() -> ok.
init() ->
    SoName = filename:join(code:priv_dir(knot), "knot"),
    erlang:load_nif(SoName, 0).

%% @doc Return a uniformly distributed integer in `1..N'.
%%
%% `N' must be a positive integer that fits in an unsigned 32-bit
%% int (i.e. `1..4294967295'). Values outside that range raise
%% `badarg'.
-spec uniform(1..4294967295) -> 1..4294967295.
uniform(_N) ->
    erlang:nif_error(knot_nif_not_loaded).
