.PHONY: setup dev test build migrate reset

setup:
	mix deps.get
	mix ecto.setup

dev:
	mix phx.server

test:
	MIX_ENV=test mix test

test.watch:
	MIX_ENV=test mix test.watch

migrate:
	DATABASE_URL=$$DATABASE_URL_UNPOOLED mix ecto.migrate

migrate.rollback:
	DATABASE_URL=$$DATABASE_URL_UNPOOLED mix ecto.rollback

migrate.reset:
	DATABASE_URL=$$DATABASE_URL_UNPOOLED mix ecto.reset

lint:
	mix credo --strict

type-check:
	mix dialyzer

security:
	mix sobelow --config

gen.migration:
	mix ecto.gen.migration $(name)

gen.worker:
	mix phx.gen.context Workers $(name) workers/$(name)