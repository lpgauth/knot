.PHONY: all compile test ct dialyzer xref clean

all: compile

compile:
	rebar3 compile

test: ct

ct:
	rebar3 ct

dialyzer:
	rebar3 dialyzer

xref:
	rebar3 xref

clean:
	rebar3 clean
	rm -rf _build priv/knot.so
