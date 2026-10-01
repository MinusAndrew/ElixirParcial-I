defmodule Programa do
  @moduledoc """
  Módulo principal que orquesta la ejecución del programa y la interacción con el usuario.
  Une todas las funciones puras e impuras en un flujo lógico para el parcial.
  """

  @doc """
  Función principal que ejecuta todo el flujo de trabajo de la finca cafetera.
  """
  def main do
    # 1. load the base data, don't touch Datos module as requested
    recolectores = Datos.recolectores()
    lotes = Datos.lotes()
    pesajes_iniciales = Datos.pesajes()

    # 2. B.5: ask the user for one more pesaje just in case they forgot someone
    pesajes_totales = procesar_pesaje_adicional(pesajes_iniciales, recolectores, lotes)

    # 3. separate the good stuff from the trash, handle errors gracefully
    {pesajes_validos, _pesajes_invalidos} =
      obtener_pesajes_validos(pesajes_totales, recolectores, lotes)

    # 4. calculate the payroll for everyone so they don't complain
    liquidaciones = Liquidacion.liquidar_todos(recolectores, pesajes_validos)

    # 5. show off the reports (prints the shiii)
    Util.imprimir_mensaje("")
    Reportes.kilos_por_lote(pesajes_validos, lotes)
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.mejor_calidad(pesajes_validos, recolectores))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.totales_semana(liquidaciones))
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.recolectores_en_todos_los_lotes(pesajes_validos, lotes, recolectores))

    # 6. Parte C: Investigación (show off the keyword lists and maps merge)
    Util.imprimir_mensaje("\n" <> Reportes.ranking_demostracion(liquidaciones))
    Util.imprimir_mensaje("\n" <> Reportes.combinar_fincas_demostracion(pesajes_validos) <> "\n")

    # 7. B.5: give the poor guy his receipt interactively
    codigo = Util.pedir_codigo_desprendible()
    Util.imprimir_mensaje("")
    Util.imprimir_mensaje(Reportes.desprendible_pago(recolectores, pesajes_validos, codigo))
  end

  # --- Funciones auxiliares de carga y validación ---

  # parses the extra input and validates it right away
  defp procesar_pesaje_adicional(pesajes, recolectores, lotes) do
    case Util.leer_pesaje_adicional() do
      {:ok, :omitido} ->
        Util.imprimir_mensaje("No se agregó ningún pesaje.")
        pesajes

      {:ok, nuevo_pesaje} ->
        case Validacion.validador_pesaje(recolectores, lotes, nuevo_pesaje) do
          {:ok, _} ->
            Util.imprimir_mensaje(
              "Pesaje agregado: #{nuevo_pesaje.recolector} en #{nuevo_pesaje.lote}, día #{nuevo_pesaje.dia}, #{nuevo_pesaje.kilos} kg, #{Util.formatear_decimal(nuevo_pesaje.verdes, 1)} % de verdes."
            )

            pesajes ++ [nuevo_pesaje]

          {:error, motivo} ->
            Util.imprimir_mensaje("Pesaje rechazado: #{motivo}")
            pesajes
        end

      {:error, motivo} ->
        Util.imprimir_mensaje("Pesaje rechazado: #{motivo}")
        pesajes
    end
  end

  # runs the validation over the entire dataset and splits the results
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
end

Programa.main()
