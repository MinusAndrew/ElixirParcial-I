# Integrantes Jacobo Londoño Davila, Andrés Camilo Gómez Lozano
defmodule Validacion do
  @moduledoc """
  Módulo puro encargado de aplicar las reglas de validación sobre cada pesaje.
  Se asegura de que ningún dato corrupto pase a la liquidación o a los reportes.
  """

  @kilos_maximos 250
  @max_dia_cosecha 6

  @doc """
  Valida un pesaje contra todas las reglas del negocio en el orden estricto.
  """
  def validador_pesaje(recolectores, lotes, pesaje) do
    # we get all the valid IDs so we can check membership
    lista_de_codigos =
      Enum.map(recolectores, fn codigo_recolector -> codigo_recolector.codigo end)

    lista_de_lotes = Enum.map(lotes, fn lote_id -> lote_id.id end)

    # the with statement from hell that checks everything in order
    with {:ok, _} <- validar_pesaje(pesaje.recolector, lista_de_codigos),
         {:ok, _} <- validar_lote(pesaje.lote, lista_de_lotes),
         {:ok, _} <- validar_dia(pesaje.dia),
         {:ok, _} <- validar_kilos(pesaje.kilos),
         {:ok, _} <- validar_porcentaje_verdes(pesaje.verdes) do
      {:ok, pesaje}
    end
  end

  # check if the recolector actually exists in our data
  defp validar_pesaje(codigo_recolector, lista_de_codigos) do
    if codigo_recolector in lista_de_codigos do
      {:ok, codigo_recolector}
    else
      {:error, :recolector_desconocido}
    end
  end

  # check if the piece of land exists
  defp validar_lote(lote_id, lista_de_lotes) do
    if lote_id in lista_de_lotes do
      {:ok, lote_id}
    else
      {:error, :lote_desconocido}
    end
  end

  # days are 1 to 6 bro, don't invent new days
  defp validar_dia(dia) when is_integer(dia) and dia >= 1 and dia <= @max_dia_cosecha do
    {:ok, dia}
  end

  defp validar_dia(_dia) do
    {:error, :dia_invalido}
  end

  # kilos must be > 0 and <= 250
  defp validar_kilos(kilos)
       when (is_integer(kilos) or is_float(kilos)) and kilos > 0 and kilos <= @kilos_maximos do
    {:ok, kilos}
  end

  defp validar_kilos(_kilos) do
    {:error, :kilos_fuera_de_rango}
  end

  # green percentage is 0 to 100
  defp validar_porcentaje_verdes(verdes)
       when (is_integer(verdes) or is_float(verdes)) and verdes >= 0 and verdes <= 100 do
    {:ok, verdes}
  end

  defp validar_porcentaje_verdes(_verdes) do
    {:error, :porcentaje_invalido}
  end
end
