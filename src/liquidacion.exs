defmodule Liquidacion do
  @moduledoc """
  Módulo puro que contiene las reglas de negocio para liquidar pagos, bonificaciones y descuentos.
  No produce efectos secundarios.
  """

  # base constants for the money
  @tarifa_base 1000.0

  @kilos_diarios_bonificacion 120
  @bonificacion_diaria 8_000.0
  @descuento_alimentacion 12_000.0

  # rules for the green coffee penalty
  @bonificacion_verdes 1.05
  @descuento_verdes_1 0.90
  @descuento_verdes_2 0.70

  @doc """
  Calcula el valor de un pesaje dependiendo de la cantidad de granos verdes.
  """
  def valor_pesaje(pesaje) when pesaje.verdes <= 2 do
    pesaje.kilos * @tarifa_base * @bonificacion_verdes
  end

  def valor_pesaje(pesaje) when pesaje.verdes > 2 and pesaje.verdes <= 5 do
    pesaje.kilos * @tarifa_base
  end

  def valor_pesaje(pesaje) when pesaje.verdes > 5 and pesaje.verdes <= 10 do
    pesaje.kilos * @tarifa_base * @descuento_verdes_1
  end

  def valor_pesaje(pesaje) when pesaje.verdes > 10 do
    pesaje.kilos * @tarifa_base * @descuento_verdes_2
  end

  # the good stuff, bonus for working hard
  @doc """
  Otorga una bonificación si el recolector supera la meta diaria de kilos.
  """
  def bonificacion_productividad(kilos_diarios)
      when kilos_diarios >= @kilos_diarios_bonificacion do
    @bonificacion_diaria
  end

  def bonificacion_productividad(_kilos_diarios) do
    0.0
  end

  # food is not free lmao
  @doc """
  Aplica el descuento de alimentación por cada día trabajado si el recolector está inscrito.
  """
  def descuento_alimentacion(dias_trabajados, tiene_alimentacion) do
    if tiene_alimentacion do
      dias_trabajados * @descuento_alimentacion
    else
      0.0
    end
  end

  @doc """
  Suma pesajes y bonificaciones, y resta el descuento de alimentación para obtener el neto.
  """
  def liquidacion_total(suma_pesajes, bonificaciones, descuento_alimentacion) do
    suma_pesajes + bonificaciones - descuento_alimentacion
  end

  # liquidar_recolector: calculate the whole paycheck for a single dude
  @doc """
  Liquida por completo a un recolector basado en sus pesajes válidos.
  """
  def liquidar_recolector(recolector, pesajes_validos) do
    pesajes_r = Enum.filter(pesajes_validos, fn p -> p.recolector == recolector.codigo end)
    kilos = pesajes_r |> Enum.map(fn p -> p.kilos end) |> Enum.sum()
    pesajes_suma = pesajes_r |> Enum.map(fn p -> valor_pesaje(p) end) |> Enum.sum()
    
    # group his work by day to see if he gets a bonus
    pesajes_por_dia = Enum.group_by(pesajes_r, fn p -> p.dia end)
    dias_trabajados = map_size(pesajes_por_dia)

    bonificaciones =
      Enum.reduce(pesajes_por_dia, 0.0, fn {_dia, pesajes_dia}, acc ->
        kilos_dia = pesajes_dia |> Enum.map(fn p -> p.kilos end) |> Enum.sum()
        acc + bonificacion_productividad(kilos_dia)
      end)

    alimentacion = descuento_alimentacion(dias_trabajados, recolector.alimentacion)
    neto = liquidacion_total(pesajes_suma, bonificaciones, alimentacion)

    %{
      codigo: recolector.codigo,
      nombre: recolector.nombre,
      kilos: kilos,
      pesajes_suma: pesajes_suma,
      bonificaciones: bonificaciones,
      alimentacion: alimentacion,
      neto: neto,
      dias_trabajados: dias_trabajados,
      pesajes_por_dia: pesajes_por_dia
    }
  end

  # liquidar_todos: just map over everyone
  @doc """
  Liquida a todos los recolectores de la base de datos.
  """
  def liquidar_todos(recolectores, pesajes_validos) do
    Enum.map(recolectores, fn r -> liquidar_recolector(r, pesajes_validos) end)
  end
end
