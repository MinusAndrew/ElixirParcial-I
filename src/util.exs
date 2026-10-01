# Integrantes Jacobo Londoño Davila, Andrés Camilo Gómez Lozano
defmodule Util do
  @moduledoc """
  Módulo de utilidades impuras para interacción con el usuario (I/O) y formateo de datos.
  Contiene toda la magia negra de leer de consola y mostrar errores.
  """

  @doc """
  Lee una cadena de texto, entero o flotante desde la consola.
  """
  # read strings
  def leer(mensaje, :string) do
    IO.gets(mensaje)
    |> String.trim()
  end

  # read integers with a default fallback
  def leer(mensaje, :integer) do
    # Se pasa la función de parseo y el valor por defecto
    leer_con_parser(mensaje, &Integer.parse/1, 0)
  end

  # read float
  def leer(mensaje, :float) do
    # Para flotantes el valor por defecto es 0.0
    leer_con_parser(mensaje, &Float.parse/1, 0.0)
  end

  # parser helper so we don't crash when user puts trash
  defp leer_con_parser(mensaje, funcion, valor_defecto) do
    valor =
      IO.gets(mensaje)
      |> String.trim()
      # Se ejecuta la función de parseo
      |> funcion.()

    case valor do
      {numero, _} ->
        numero

      :error ->
        imprimir_error("Error. Se utilizará #{valor_defecto} como valor predeterminado.")
        valor_defecto
    end
  end

  @doc """
  Imprime mensajes de error al stderr.
  """
  def imprimir_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  @doc """
  Imprime mensajes estándar al stdout.
  """
  def imprimir_mensaje(mensaje) do
    IO.puts(mensaje)
  end

  # B.5: read the extra pesaje from the console in one string
  @doc """
  Solicita y parsea un pesaje adicional con formato csv-like.
  """
  def leer_pesaje_adicional do
    linea =
      IO.gets(
        "Ingrese un pesaje adicional (recolector;lote;dia;kilos;verdes) o Enter para omitir: "
      )
      |> to_string()
      |> String.trim()

    parsear_pesaje_linea(linea)
  end

  defp parsear_pesaje_linea("") do
    {:ok, :omitido}
  end

  defp parsear_pesaje_linea(linea) do
    partes = String.split(linea, ";")

    if length(partes) == 5 do
      [recolector, lote, dia_s, kilos_s, verdes_s] = Enum.map(partes, &String.trim/1)

      with {:ok, dia} <- parse_entero(dia_s),
           {:ok, kilos} <- parse_numero(kilos_s),
           {:ok, verdes} <- parse_numero(verdes_s) do
        {:ok, %{recolector: recolector, lote: lote, dia: dia, kilos: kilos, verdes: verdes}}
      else
        _ -> {:error, :formato_invalido}
      end
    else
      {:error, :formato_invalido}
    end
  end

  defp parse_entero(str) do
    case Integer.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> :error
    end
  end

  defp parse_numero(str) do
    case Float.parse(str) do
      {num, ""} ->
        {:ok, num}

      _ ->
        case Integer.parse(str) do
          {num, ""} -> {:ok, num * 1.0}
          _ -> :error
        end
    end
  end

  @doc """
  Pide el código de recolector para imprimir su colilla de pago.
  """
  def pedir_codigo_desprendible do
    IO.gets("Ingrese el código del recolector para ver su desprendible: ")
    |> to_string()
    |> String.trim()
  end

  # format money to 2 decimals so it doesn't look ugly
  @doc """
  Formatea un número a representación de moneda con 2 decimales.
  """
  def formatear_pesos(num) when is_number(num) do
    :erlang.float_to_binary(num * 1.0, decimals: 2)
  end

  @doc """
  Formatea un decimal a `dec` posiciones decimales (por defecto 2).
  """
  def formatear_decimal(num, dec \\ 2) when is_number(num) do
    :erlang.float_to_binary(num * 1.0, decimals: dec)
  end
end
