-module(knot).

-on_load(init/0).

-export([uniform/1]).

-spec init() -> ok.
init() ->
    SoName = filename:join(code:priv_dir(knot), "knot"),
    erlang:load_nif(SoName, 0).

-spec uniform(pos_integer()) -> pos_integer().
uniform(_N) ->
    erlang:nif_error(knot_nif_not_loaded).
