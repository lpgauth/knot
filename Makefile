.PHONY: all compile test ct bench dialyzer xref clean

all: compile

compile:
	rebar3 compile

test: ct

ct:
	rebar3 ct

bench:
	rebar3 as bench compile
	./bin/bench.sh

dialyzer:
	rebar3 dialyzer

xref:
	rebar3 xref

clean:
	rebar3 clean
	rm -rf _build priv/rotor.so
