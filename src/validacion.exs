defmodule Validacion do
  @kilos_maximos 250

  def validador_pesajes(recolectores, lotes, pesaje) do
    lista_de_codigos =
      Enum.map(recolectores, fn codigo_recolector -> codigo_recolector.codigo end)

    lista_de_lotes = Enum.map(lotes, fn lote_id -> lote_id.id end)

    with {:ok, _} <- validar_pesaje(pesaje.recolector, lista_de_codigos),
         {:ok, _} <- validar_lote(pesaje.lote, lista_de_lotes),
         {:ok, _} <- validar_dia(pesaje.dia),
         {:ok, _} <- validar_kilos(pesaje.kilos),
         {:ok, _} <- validar_porcentaje_verdes(pesaje.verdes) do
      {:ok, pesaje}
    end
  end

  defp validar_pesaje(codigo_recolector, lista_de_codigos) do
    if codigo_recolector in lista_de_codigos do
      {:ok, codigo_recolector}
    else
      {:error, :recolector_desconocido}
    end
  end

  defp validar_lote(lote_id, lista_de_lotes) do
    if lote_id in lista_de_lotes do
      {:ok, lote_id}
    else
      {:error, :lote_desconocido}
    end
  end

  defp validar_dia(dia) when is_integer(dia) in 1..6 do
    {:ok, dia}
  end

  defp validar_dia(_dia) do
    {:error, :dia_invalido}
  end

  defp validar_kilos(kilos) when is_integer(kilos) in 0..@kilos_maximos do
    {:ok, kilos}
  end

  defp validar_kilos(_kilos) do
    {:error, :kilos_fuera_de_rango}
  end

  defp validar_porcentaje_verdes(verdes)
       when (is_integer(verdes) or is_float(verdes)) and verdes >= 0 and verdes <= 100 do
    {:ok, verdes}
  end

  defp validar_porcentaje_verdes(_verdes) do
    {:error, :porcentaje_invalido}
  end
end
