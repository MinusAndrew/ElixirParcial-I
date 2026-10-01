#!/bin/sh

cd src/

elixirc datos.exs validacion.exs liquidacion.exs reportes.exs util.exs
elixir programa.exs
