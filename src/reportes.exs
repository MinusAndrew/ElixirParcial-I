defmodule Reportes do
  @moduledoc """
  Módulo encargado de la generación de reportes y consultas de la finca.
  Aquí está todo el desastre que imprime cosas y arma strings larguísimos.
  """
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
        " #{nombre_lote} | #{kilos_totales} kg  | #{hectareas_lote} ha | #{Util.formatear_pesos(kilos_hectarea)} kg/ha"
      )

      # madness.
    end)
  end

  # Kilos por día (mapa para C.2)
  def kilos_por_dia_mapa(pesajes) do
    # group all pesajes by day so we can map them later
    pesajes_por_dia = Enum.group_by(pesajes, fn p -> p.dia end)

    # loop from day 1 to 6 creating our map from scratch using reduce
    Enum.reduce(1..6, %{}, fn dia, acc ->
      # for each day we grab the pesajes, extract just the kilos with Enum.map, and sum them all up
      kilos = pesajes_por_dia |> Map.get(dia, []) |> Enum.map(fn p -> p.kilos end) |> Enum.sum()
      # stick the result into our accumulator map
      Map.put(acc, dia, kilos)
    end)
  end

  # R6: Mejor calidad (mínimo 3 pesajes válidos)
  @doc """
  Calcula quién tiene la mejor calidad de café basado en porcentaje de verdes.
  """
  def mejor_calidad(pesajes_validos, recolectores) do
    # group the pesajes by the dude who collected them
    pesajes_por_recolector = Enum.group_by(pesajes_validos, fn p -> p.recolector end)
    # turn the list of recolectores into a map so we can look them up instantly by id
    recolectores_map = Map.new(recolectores, fn r -> {r.codigo, r} end)

    # filter out the ones who didn't even work 3 times, others get kicked out
    calificados =
      Enum.filter(pesajes_por_recolector, fn {_codigo, pesajes} ->
        length(pesajes) >= 3
      end)

    case calificados do
      [] ->
        "R6. Mejor calidad (mínimo 3 pesajes válidos)\nNo hay recolectores con al menos 3 pesajes válidos."

      _ ->
        # we map over the surviving dudes to do the math
        ponderados =
          Enum.map(calificados, fn {codigo, pesajes} ->
            # just add up all their kilos
            suma_kilos = Enum.map(pesajes, fn p -> p.kilos end) |> Enum.sum()
            # multiply their green coffee by the kilos to get the total penalty weight
            suma_verdes_kilos = Enum.map(pesajes, fn p -> p.verdes * p.kilos end) |> Enum.sum()
            # calculate the weighted average so we don't divide by zero and blow everything up
            promedio_ponderado = if suma_kilos > 0, do: suma_verdes_kilos / suma_kilos, else: 0.0
            recolector = recolectores_map[codigo]
            {recolector, promedio_ponderado}
          end)

        # we find the absolute lowest percentage of green coffee using min_by
        {mejor_rec, mejor_pct} =
          Enum.min_by(ponderados, fn {_rec, pct} -> pct end)

        """
        R6. Mejor calidad (mínimo 3 pesajes válidos)
        #{mejor_rec.nombre}, con #{Util.formatear_decimal(mejor_pct)} % de verdes ponderado por kilos
        """
        |> String.trim_trailing()
    end
  end

  # B.5: Desprendible de pago para un recolector
  @doc """
  Genera el string con la colilla de pago para un recolector específico.
  """
  def desprendible_pago(recolectores, pesajes_validos, codigo) do
    # look for the exact guy the user typed in
    case Enum.find(recolectores, fn r -> r.codigo == codigo end) do
      nil ->
        "No existe un recolector con el código #{codigo}."

      recolector ->
        # give the poor guy his receipt
        # filter out only the pesajes that belong to this specific guy
        pesajes_rec = Enum.filter(pesajes_validos, fn p -> p.recolector == codigo end)
        # group his work by day so we can print it row by row
        pesajes_por_dia = Enum.group_by(pesajes_rec, fn p -> p.dia end)
        # grab the days he worked and sort them so it doesn't look messy
        dias_ordenados = Map.keys(pesajes_por_dia) |> Enum.sort()

        # map over his days to build the receipt lines
        lineas_dias =
          Enum.map(dias_ordenados, fn dia ->
            pesajes_dia = pesajes_por_dia[dia]
            # get how many kilos he got that day
            kilos_dia = Enum.map(pesajes_dia, fn p -> p.kilos end) |> Enum.sum()

            # calculate how much cash he gets for those kilos
            valor_pesajes_dia =
              Enum.map(pesajes_dia, fn p -> Liquidacion.valor_pesaje(p) end) |> Enum.sum()

            bono_dia = Liquidacion.bonificacion_productividad(kilos_dia)

            "Día #{dia}: #{kilos_dia} kg | pesajes $#{Util.formatear_pesos(valor_pesajes_dia)} | bonificación $#{Util.formatear_pesos(bono_dia)}"
          end)

        # sum all his cash for the whole week
        suma_pesajes =
          Enum.map(pesajes_rec, fn p -> Liquidacion.valor_pesaje(p) end) |> Enum.sum()

        dias_trabajados = length(dias_ordenados)

        # reduce over his days again to sum up all his daily bonuses
        bonificaciones =
          Enum.reduce(pesajes_por_dia, 0.0, fn {_dia, p_dia}, acc ->
            kilos_dia = Enum.map(p_dia, fn p -> p.kilos end) |> Enum.sum()
            acc + Liquidacion.bonificacion_productividad(kilos_dia)
          end)

        alimentacion =
          Liquidacion.descuento_alimentacion(dias_trabajados, recolector.alimentacion)

        neto = Liquidacion.liquidacion_total(suma_pesajes, bonificaciones, alimentacion)

        """
        Desprendible de pago - #{recolector.nombre} (#{recolector.codigo})
        #{Enum.join(lineas_dias, "\n")}
        Suma de pesajes: $#{Util.formatear_pesos(suma_pesajes)}
        Bonificaciones: $#{Util.formatear_pesos(bonificaciones)}
        Alimentación (#{dias_trabajados} días): -$#{Util.formatear_pesos(alimentacion)}
        Neto a pagar: $#{Util.formatear_pesos(neto)}
        """
        |> String.trim_trailing()
    end
  end

  # C.1: Opciones con keyword lists (función pura)
  @doc """
  Ordena y filtra la lista de liquidaciones de acuerdo a un Keyword list de opciones.
  """
  # pure function for the keyword list ranking madness
  def ranking(liquidaciones, opts \\ []) do
    campo = Keyword.get(opts, :campo, :neto)
    orden = Keyword.get(opts, :orden, :desc)
    limite = Keyword.get(opts, :limite, length(liquidaciones))

    # we sort the list of maps dynamically checking what field the user wants
    liquidaciones
    |> Enum.sort_by(
      fn liq ->
        case campo do
          :neto -> liq.neto
          :kilos -> liq.kilos
          :bruto -> liq.pesajes_suma
          _ -> liq.neto
        end
      end,
      orden
    )
    # take only the top N results based on the limite, toss the rest
    |> Enum.take(limite)
  end

  # C.1: Construcción del texto de demostración del ranking
  def ranking_demostracion(liquidaciones) do
    # map over the ranking result to build the output string for each row
    r1 =
      ranking(liquidaciones, [])
      |> Enum.map(fn liq ->
        "   #{liq.codigo} - #{liq.nombre} | Neto: $#{Util.formatear_pesos(liq.neto)}"
      end)
      |> Enum.join("\n")

    r2 =
      ranking(liquidaciones, campo: :kilos, limite: 3)
      |> Enum.map(fn liq -> "   #{liq.codigo} - #{liq.nombre} | Kilos: #{liq.kilos} kg" end)
      |> Enum.join("\n")

    r3 =
      ranking(liquidaciones, orden: :asc, campo: :bruto)
      |> Enum.map(fn liq ->
        "   #{liq.codigo} - #{liq.nombre} | Bruto: $#{Util.formatear_pesos(liq.pesajes_suma)}"
      end)
      |> Enum.join("\n")

    """
    C.1. Ranking con Keyword Lists
    1. Reportes.ranking(liquidaciones, []):
    #{r1}

    2. Reportes.ranking(liquidaciones, campo: :kilos, limite: 3):
    #{r2}

    3. Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto):
    #{r3}
    """
    |> String.trim_trailing()
  end

  # C.2: Combinar reportes de dos fincas usando Map.merge/3 (función pura)
  def combinar_fincas(finca_propia, finca_vecina) do
    # literally just combine the two maps and sum the kilos if they have the same day
    Map.merge(finca_propia, finca_vecina, fn _dia, kilos_propia, kilos_vecina ->
      kilos_propia + kilos_vecina
    end)
  end

  # C.2: Construcción del texto de demostración de combinación de fincas
  def combinar_fincas_demostracion(pesajes_validos) do
    finca_vecina = %{1 => 520.5, 2 => 610, 3 => 480, 5 => 700, 7 => 300}
    finca_propia = kilos_por_dia_mapa(pesajes_validos)
    combinada = combinar_fincas(finca_propia, finca_vecina)

    """
    C.2. Combinar reportes de dos fincas
    Finca propia (R3): #{inspect(finca_propia)}
    Finca vecina:     #{inspect(finca_vecina)}
    Fincas combinadas: #{inspect(combinada)}
    """
    |> String.trim_trailing()
  end

  # R7: Totales generales de la semana
  @doc """
  Suma toda la plata y kilos de la finca y calcula el costo promedio.
  """
  def totales_semana(liquidaciones) do
    # we just sum everything up like crazy
    # extract the neto from everyone and sum it all
    total_neto = Enum.map(liquidaciones, fn liq -> liq.neto end) |> Enum.sum()
    # sum all kilos
    total_kilos = Enum.map(liquidaciones, fn liq -> liq.kilos end) |> Enum.sum()
    # sum all gross money
    total_bruto = Enum.map(liquidaciones, fn liq -> liq.pesajes_suma end) |> Enum.sum()
    # sum up bonuses
    total_bonificaciones = Enum.map(liquidaciones, fn liq -> liq.bonificaciones end) |> Enum.sum()
    # sum up food discounts
    total_alimentacion = Enum.map(liquidaciones, fn liq -> liq.alimentacion end) |> Enum.sum()

    # get the average cost if we actually collected something
    costo_kilo = if total_kilos > 0, do: total_neto / total_kilos, else: 0.0

    """
    R7. Totales de la semana
    Kilos totales recolectados: #{total_kilos} kg
    Suma bruta de pesajes:      $#{Util.formatear_pesos(total_bruto)}
    Total bonificaciones:       $#{Util.formatear_pesos(total_bonificaciones)}
    Total descuentos alimentacion: $#{Util.formatear_pesos(total_alimentacion)}
    Total neto pagado:          $#{Util.formatear_pesos(total_neto)}
    Costo promedio por kilo:    $#{Util.formatear_decimal(costo_kilo)} / kg
    """
    |> String.trim_trailing()
  end

  # R8: Recolectores que trabajaron en TODOS los lotes
  @doc """
  Identifica cuáles recolectores tuvieron presencia en todos los lotes de la finca.
  """
  def recolectores_en_todos_los_lotes(pesajes_validos, lotes, recolectores) do
    # pull out just the lote ids into a list (get all the freaking land ids)
    todos_los_lotes = Enum.map(lotes, fn l -> l.id end)

    # group the pesajes by dude
    pesajes_por_recolector = Enum.group_by(pesajes_validos, fn p -> p.recolector end)

    # map the recolectores so we have the full data instantly available
    recolectores_map = Map.new(recolectores, fn r -> {r.codigo, r} end)

    # filter the ones that meet our crazy condition
    todos =
      Enum.filter(recolectores_map, fn {codigo, _r} ->
        pesajes_del_rec = Map.get(pesajes_por_recolector, codigo, [])
        # get all the lotes this dude worked on and make them unique so no duplicates
        lotes_del_rec = Enum.map(pesajes_del_rec, fn p -> p.lote end) |> Enum.uniq()
        # check if ALL existing lotes are in the list of lotes he worked on
        Enum.all?(todos_los_lotes, fn lote_id -> lote_id in lotes_del_rec end)
      end)

    case todos do
      [] ->
        "R8. Recolectores en todos los lotes\nNingún recolector trabajó en todos los lotes."

      _ ->
        lineas =
          Enum.map(todos, fn {_codigo, r} -> "  #{r.codigo} - #{r.nombre}" end)
          |> Enum.join("\n")

        "R8. Recolectores en todos los lotes\n#{lineas}"
    end
  end
end
