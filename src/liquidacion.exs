defmodule Liquidacion do
  @tarifa_base 1000.0

  @kilos_diarios_bonificacion 120
  @bonificacion_diaria 8_000.0
  @descuento_alimentacion 12_000.0

  @bonificacion_verdes 1.05
  @descuento_verdes_1 0.90
  @descuento_verdes_2 0.70

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

  def bonificacion_productividad(kilos_diarios)
      when kilos_diarios >= @kilos_diarios_bonificacion do
    @bonificacion_diaria
  end

  def bonificacion_productividad(_kilos_diarios) do
    0.0
  end

  def descuento_alimentacion(dias_trabajados, tiene_alimentacion) do
    if tiene_alimentacion do
      dias_trabajados * @descuento_alimentacion
    else
      0.0
    end
  end

  def liquidacion_total(suma_pesajes, bonificaciones, descuento_alimentacion) do
    suma_pesajes + bonificaciones - descuento_alimentacion
  end
end
