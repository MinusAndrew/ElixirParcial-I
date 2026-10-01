defmodule Reportes do
  @meta_finca 400

  # I'm fucking insane.
  def kilos_por_lote(pesajes, lotes) do
    # gets lotes per id
    lotes_per_id = Enum.group_by(lotes, fn lote -> lote.id end)

    # lotes of each pesajes
    lotes_pesaje = Enum.group_by(pesajes, fn pesaje -> pesaje.lote end)

    # lotes per how big the piece of land is, and we make it a map
    hectareas_lote = Enum.map(lotes, fn lotes -> {lotes.id, lotes.hectareas} end) |> Map.new()

    # we get the total of kilos per land
    kilos_por_lote =
      Enum.map(lotes_pesaje, fn {key, pesajes} ->
        {key, Enum.sum_by(pesajes, fn pesaje -> pesaje.kilos end)}
      end)

    # we get each of the possible list of lotes id
    lista_de_lotes = Enum.map(kilos_por_lote, fn {key, _} -> key end)

    # we create a map for the total of kilos per land
    map_kilos_lote = Map.new(kilos_por_lote)

    # we merge every result we got
    mapa_completo_kilos_lote =
      Map.merge(hectareas_lote, map_kilos_lote, fn _key, hectareas, kilos ->
        %{hectareas: hectareas, kilos_totales: kilos}
      end)

    # we build our report
    datos_reportes =
      Enum.map(lista_de_lotes, fn key_lote ->
        # we access our current land
        lote_seleccionado = mapa_completo_kilos_lote[key_lote]

        # extract the data as a tuple
        {key_lote, lote_seleccionado.hectareas, lote_seleccionado.kilos_totales,
         lote_seleccionado.kilos_totales / lote_seleccionado.hectareas}
      end)
      # we sort it by how well it behaves according to kg per land
      |> Enum.sort_by(fn {_lote, _ha, _kg, rendimiento} -> rendimiento end, :desc)

    Util.imprimir_mensaje("R2. Kilos por lote")

    # we start printing each of our tuples based on the id we have, as I forgot to add the name of the piece
    # of land I got mad and just got from the first map
    Enum.each(datos_reportes, fn {lote, hectareas_lote, kilos_totales, kilos_hectarea} ->
      lote_actual = lotes_per_id[lote]

      [%{nombre: nombre_lote}] = lote_actual
      # prints the shiii
      Util.imprimir_mensaje(
        " #{nombre_lote} | #{kilos_totales} kg  | #{hectareas_lote} ha | #{kilos_hectarea} kg/ha"
      )

      # madness.
    end)
  end
end
