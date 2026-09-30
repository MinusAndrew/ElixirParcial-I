defmodule Programa do
  def main do
    pesajes = Datos.pesajes()
    recolectores = Datos.recolectores()
    lotes = Datos.lotes()

    {pesajes_validos, _pesajes_invalidos} = obtener_pesajes_validos(pesajes, recolectores, lotes)

    quick_check(pesajes_validos, recolectores)
  end

  defp obtener_pesajes_validos(pesajes, recolectores, lotes) do
    {pesajes_validos, pesajes_invalidos} =
      Enum.reduce(pesajes, {[], []}, fn p, {validos, invalidos} ->
        case Validacion.validador_pesaje(recolectores, lotes, p) do
          {:ok, _} -> {[p | validos], invalidos}
          {:error, motivo} -> {validos, [{p, motivo} | invalidos]}
        end
      end)

    {pesajes_validos, pesajes_invalidos}
  end

  # Todo Check case
  defp quick_check(pesajes_validos, recolectores) do
    # 1. Obtener el mapa de nuestro recolector
    our_recolector = Enum.find(recolectores, fn r -> r.codigo == "R01" end)

    # 2. Filtrar solo los pesajes de R01
    our_pesajes = Enum.filter(pesajes_validos, fn p -> p.recolector == "R01" end)

    # 3. Kilos totales
    kilos_total = Enum.sum(Enum.map(our_pesajes, fn p -> p.kilos end))

    # 4. Suma del valor de los pesajes usando Liquidacion.valor_pesaje/1
    valor_total_pesajes = Enum.sum(Enum.map(our_pesajes, fn p -> Liquidacion.valor_pesaje(p) end))

    # this Agrupar pesajes por día para bono y conteo de días trabajados
    pesajes_por_dia = Enum.group_by(our_pesajes, fn p -> p.dia end)

    # this Contar días trabajados es contar cuántos días diferentes hay en el mapa
    count_days = map_size(pesajes_por_dia)

    # 6. Calcular bonificaciones usando bonificacion_productividad
    suma_bonificacion =
      Enum.reduce(pesajes_por_dia, 0, fn {_dia, pesajes_del_dia}, total_acumulado ->
        kilos_del_dia = Enum.sum(Enum.map(pesajes_del_dia, fn p -> p.kilos end))
        bono = Liquidacion.bonificacion_productividad(kilos_del_dia)
        total_acumulado + bono
      end)

    # 7. Calcular el descuento de alimentación
    descuento_alimentacion =
      Liquidacion.descuento_alimentacion(count_days, our_recolector.alimentacion)

    # 8. Calcular el total neto
    total_neto =
      Liquidacion.liquidacion_total(
        valor_total_pesajes,
        suma_bonificacion,
        descuento_alimentacion
      )

    # the only thing AI was used
    IO.inspect(pesajes_por_dia)
    IO.puts("\n--- QUICK CHECK: #{our_recolector.nombre} (#{our_recolector.codigo}) ---")
    IO.puts("Kilos totales recogidos: #{kilos_total} kg")
    IO.puts("Días trabajados: #{count_days}")
    IO.puts("Suma de pesajes: $#{formatear_numero(valor_total_pesajes)}")
    IO.puts("Bonificaciones: $#{formatear_numero(suma_bonificacion)}")
    IO.puts("Alimentación: -$#{formatear_numero(descuento_alimentacion)}")
    IO.puts("Neto a pagar: $#{formatear_numero(total_neto)}\n")
  end

  defp formatear_numero(num), do: :erlang.float_to_binary(num, decimals: 2)
end

Programa.main()
