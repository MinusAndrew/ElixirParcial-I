#!/bin/sh

cd src/

rm -f *.beam

elixirc datos.exs validacion.exs liquidacion.exs reportes.exs util.exs
elixir programa.exs
