defmodule Reportes do
  @meta_finca 400

  def reporte_r1(rechazados) do
    rec =
      Enum.reduce(rechazados, "", fn r, acc ->
        acc <> organizar_pesajes_rechazados(r) <> "\n"
      end)

    "R1. Pesajes rechazados\n" <>
      rec <> "\n" <> "Rechazos por motivo\n" <> cantidad_rechazos_por_motivo(rechazados)
  end

  defp organizar_pesajes_rechazados({r, motivo}) do
    "#{r.recolector} | #{r.lote} | dia #{r.dia} | #{r.kilos} kg   | #{r.verdes} %   | -> #{motivo}"
  end

  defp cantidad_rechazos_por_motivo(rechazados) do
    rechazados
    |> Enum.frequencies_by(fn {_pesaje, motivo} -> motivo end)
    |> Enum.map(fn {motivo, cantidad} -> "#{motivo}: #{cantidad}" end)
    |> Enum.join("\n")
  end

  def reporte_r2(pesajes) do
    {kilos1, kilos2, kilos3, kilos4, kilos5, kilos6} = total_kilos_dia(pesajes)

    {meta1, meta2, meta3, meta4, meta5, meta6} =
      supera_la_meta({kilos1, kilos2, kilos3, kilos4, kilos5, kilos6})

    {diaria, una} = cumplio_meta({meta1, meta2, meta3, meta4, meta5, meta6})

    "
    R2. Kilo-tes (Meta: #{@meta_finca} kg) (andres no me mates por poner ki-lotes)
    Día 1: #{kilos1} kg -> Cumplio la meta? #{meta1}
    Día 2: #{kilos2} kg -> Cumplio la meta? #{meta2}
    Día 3: #{kilos3} kg -> Cumplio la meta? #{meta3}
    Día 4: #{kilos4} kg -> Cumplio la meta? #{meta4}
    Día 5: #{kilos5} kg -> Cumplio la meta? #{meta5}
    Día 6: #{kilos6} kg -> Cumplio la meta? #{meta6}
    ¿Se cumplió la meta todos los días? #{diaria}
    ¿Se cumplió la meta al menos un día? #{una}"
  end

  defp total_kilos_dia(pesajes) do
    total_recolectores = {0, 0, 0, 0, 0, 0}

    Enum.reduce(pesajes, total_recolectores, fn x, {k1, k2, k3, k4, k5, k6} ->
      dia = x.dia
      kilos = x.kilos

      cond do
        dia == 1 -> {k1 + kilos, k2, k3, k4, k5, k6}
        dia == 2 -> {k1, k2 + kilos, k3, k4, k5, k6}
        dia == 3 -> {k1, k2, k3 + kilos, k4, k5, k6}
        dia == 4 -> {k1, k2, k3, k4 + kilos, k5, k6}
        dia == 5 -> {k1, k2, k3, k4, k5 + kilos, k6}
        true -> {k1, k2, k3, k4, k5, k6 + kilos}
      end
    end)
  end

  defp supera_la_meta({kilos1, kilos2, kilos3, kilos4, kilos5, kilos6}) do
    {
      if(kilos1 >= @meta_finca, do: "Si", else: "No"),
      if(kilos2 >= @meta_finca, do: "Si", else: "No"),
      if(kilos3 >= @meta_finca, do: "Si", else: "No"),
      if(kilos4 >= @meta_finca, do: "Si", else: "No"),
      if(kilos5 >= @meta_finca, do: "Si", else: "No"),
      if(kilos6 >= @meta_finca, do: "Si", else: "No")
    }
  end

  defp cumplio_meta({meta1, meta2, meta3, meta4, meta5, meta6}) do
    metas = [meta1, meta2, meta3, meta4, meta5, meta6]
    cantidad_si = Enum.count(metas, fn x -> x == "No" end)

    cond do
      cantidad_si == 6 -> {"Si", "Si"}
      cantidad_si > 1 -> {"No", "Si"}
      !false -> {"No", "No"}
    end
  end

  def reporte_r4(recolectores, pesajes_validos) do
    Enum.map(recolectores, fn rec ->
      pesajes_del_recolector =
        Enum.filter(pesajes_validos, fn pesaje -> pesaje.recolector == rec.codigo end)

      kilos_totales = Enum.sum(Enum.map(pesajes_del_recolector, fn pesaje -> pesaje.kilos end))

      suma_pesajes =
        Enum.sum(
          Enum.map(pesajes_del_recolector, fn pesaje -> Liquidacion.valor_pesaje(pesaje) end)
        )

      pesajes_por_dia = Enum.group_by(pesajes_del_recolector, fn pesaje -> pesaje.dia end)
      dias_trabajados = map_size(pesajes_por_dia)

      bonificaciones =
        pesajes_por_dia
        |> Enum.map(fn {_dia, pesajes_dia} ->
          kilos_dia = Enum.sum(Enum.map(pesajes_dia, fn pesaje -> pesaje.kilos end))
          Liquidacion.bonificacion_productividad(kilos_dia)
        end)
        |> Enum.sum()

      alimentacion = Liquidacion.descuento_alimentacion(dias_trabajados, rec.alimentacion)
      neto = Liquidacion.liquidacion_total(suma_pesajes, bonificaciones, alimentacion)

      %{
        nombre: rec.nombre,
        kilos: kilos_totales,
        pesajes: suma_pesajes,
        bonificaciones: bonificaciones,
        alimentacion: alimentacion,
        neto: neto
      }
    end)
    |> Enum.sort_by(fn liquidacion -> liquidacion.neto end, :desc)
    |> Enum.with_index(1)
    |> formato_r4()
  end

  def formato_r4(resultados_r4) do
    encabezado =
      "R4. Liquidación de la semana\n
      # | Recolector | Kilos | Pesajes | Bonificaciones | Alimentación | Neto\n"

    fila =
      Enum.map(resultados_r4, fn {liq, index} ->
        pesaje = :erlang.float_to_binary(liq.pesajes, decimals: 2)
        bono = :erlang.float_to_binary(liq.bonificaciones, decimals: 2)
        alim = :erlang.float_to_binary(liq.alimentacion, decimals: 2)
        neto = :erlang.float_to_binary(liq.neto, decimals: 2)

        "#{index}. | #{liq.nombre} | #{liq.kilos} kg | $#{pesaje} | $#{bono} | $#{alim} | $#{neto}"
      end)

    encabezado <> Enum.join(fila, "\n")
  end

  def reporte_r5(pesajes_validos, recolectores) do
    ganadores_por_dia =
      for dia <- 1..6 do
        pesajes_dia = Enum.filter(pesajes_validos, fn pesaje -> pesaje.dia == dia end)

        if pesajes_dia == [] do
          %{dia: dia, ganadores: [], max_kilos: 0}
        else
          kilos_por_recolector =
            pesajes_dia
            |> Enum.group_by(fn pesaje -> pesaje.recolector end)
            |> Enum.map(fn {codigo, pesajes} ->
              {codigo, Enum.sum(Enum.map(pesajes, fn pesaje -> pesaje.kilos end))}
            end)

          {_, max_kilos} = Enum.max_by(kilos_por_recolector, fn {_, kilos} -> kilos end)

          ganadores =
            kilos_por_recolector
            |> Enum.filter(fn {_, kilos} -> kilos == max_kilos end)
            |> Enum.map(fn {codigo, _} -> codigo end)

          %{dia: dia, ganadores: ganadores, max_kilos: max_kilos}
        end
      end

    frecuencias =
      ganadores_por_dia
      |> Enum.flat_map(fn resultado_dia -> resultado_dia.ganadores end)
      |> Enum.frequencies()

    mejor_recolector =
      if frecuencias == %{} do
        []
      else
        max_veces = Enum.max(Map.values(frecuencias))
        Enum.filter(frecuencias, fn {_, veces} -> veces == max_veces end)
      end

    {ganadores_por_dia, mejor_recolector}
    formato_r5({ganadores_por_dia, mejor_recolector}, recolectores)
  end

  def formato_r5({ganadores_por_dia, mejor_recolector}, recolectores) do
    encabezado = "R5. Mejor recolector de cada día\n"

    columna_dia =
      Enum.map(ganadores_por_dia, fn resultado ->
        if resultado.ganadores == [] do
          "Día #{resultado.dia}: sin pesajes"
        else
          nombres =
            Enum.map(resultado.ganadores, fn codigo ->
              recolector = Enum.find(recolectores, fn rec -> rec.codigo == codigo end)
              recolector.nombre
            end)

          nombres_unidos = Enum.join(nombres, ", ")
          "Día #{resultado.dia}: #{nombres_unidos} (#{resultado.max_kilos} kg)"
        end
      end)

    texto_dias = Enum.join(columna_dia, "\n")

    nombres_campeones =
      Enum.map(mejor_recolector, fn {codigo, _veces} ->
        recolector = Enum.find(recolectores, fn rec -> rec.codigo == codigo end)
        recolector.nombre
      end)

    nombres_campeones_unidos = Enum.join(nombres_campeones, ", ")
    veces = if mejor_recolector == [], do: 0, else: elem(hd(mejor_recolector), 1)

    columna_final =
      "\nMás días como mejor recolector: #{nombres_campeones_unidos} (#{veces} días)"

    encabezado <> texto_dias <> columna_final
  end

  def reporte_r6(pesajes_validos) do
    pesajes_validos
    |> Enum.group_by(fn pesaje -> pesaje.recolector end)
    |> Enum.filter(fn {_codigo, pesajes} -> length(pesajes) >= 3 end)
    |> Enum.map(fn {codigo, pesajes} ->
      suma_kilos = Enum.sum(Enum.map(pesajes, fn pesaje -> pesaje.kilos end))
      suma_ponderada = Enum.sum(Enum.map(pesajes, fn pesaje -> pesaje.verdes * pesaje.kilos end))
      calidad = suma_ponderada / suma_kilos
      {codigo, calidad}
    end)
    |> Enum.min_by(fn {_codigo, calidad} -> calidad end, fn -> nil end)
    |> formato_r6()
  end

  def formato_r6(nil) do
    "R6. Mejor calidad (mínimo 3 pesajes válidos)\nNadie cumplió el requisito de 3 pesajes válidos"
  end

  def formato_r6({codigo, calidad}, recolectores) do
    recolector = Enum.find(recolectores, fn rec -> rec.codigo == codigo end)
    calidad_formateada = :erlang.float_to_binary(calidad, decimals: 2)

    "R6. Mejor calidad (mínimo 3 pesajes válidos)\n#{recolector.nombre}, con #{calidad_formateada} % de verdes ponderado por kilos"
  end
end
