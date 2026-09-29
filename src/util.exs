defmodule Util do

  def leer(mensaje, :string) do
    IO.gets(mensaje)
    |> String.trim()
  end

  def leer(mensaje, :integer) do
    leer_con_parser(mensaje, &Integer.parse/1, 0) # Se pasa la función de parseo y el valor por defecto
  end

  def leer(mensaje, :float) do
    leer_con_parser(mensaje, &Float.parse/1, 0.0) # Para flotantes el valor por defecto es 0.0
  end

  defp leer_con_parser(mensaje, funcion, valor_defecto) do
    valor = IO.gets(mensaje)
    |> String.trim()
    |> funcion.() # Se ejecuta la función de parseo

    case valor do
      {numero, _} -> numero
      :error ->
        imprimir_error("Error. Se utilizará #{valor_defecto} como valor predeterminado.")
        valor_defecto
    end
  end

  def imprimir_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  def imprimir_mensaje(mensaje) do
    IO.puts(mensaje)
  end

end
