#Carlos Arturo Moreno Arroyave
#Santiago Padilla Espinosa
#Julian David Patiño

defmodule Liquidacion do
  @moduledoc """
  Calcula el pago de los lotes y la liquidacion de los confeccionistas.
  """

  @doc "Calcula el valor de un lote valido segun su porcentaje de defectos."
  def valor_lote(lote) do
    valor_base = lote.prendas * Util.tarifa_base()

    porcentaje_pago =
      cond do
        lote.defectos <= 2 -> 107
        lote.defectos <= 5 -> 100
        lote.defectos <= 10 -> 88
        true -> 75
      end

    div(valor_base * porcentaje_pago, 100)
  end

  @doc "Suma las prendas por codigo de confeccionista y dia."
  def prendas_por_confeccionista_y_dia(lotes) do
    Enum.reduce(lotes, %{}, fn lote, acumulado ->
      clave = {lote.confeccionista, lote.dia}
      prendas_actuales = Map.get(acumulado, clave, 0)
      Map.put(acumulado, clave, prendas_actuales + lote.prendas)
    end)
  end

  @doc "Devuelve el bono diario correspondiente a una cantidad de prendas."
  def bono_diario(prendas) do
    if prendas >= Util.umbral_bonificacion() do
      Util.bonificacion_diaria()
    else
      0
    end
  end

  @doc "Suma los bonos diarios de un confeccionista a partir de sus prendas por dia."
  def bonificaciones_confeccionista(codigo, prendas_diarias) do
    Enum.reduce(Util.dias_produccion(), 0, fn dia, total_bonos ->
      prendas = Map.get(prendas_diarias, {codigo, dia}, 0)
      total_bonos + bono_diario(prendas)
    end)
  end

  @doc "Cuenta los dias en que hay al menos un lote valido."
  def dias_trabajados(lotes) do
    lotes
    |> Enum.map(fn lote -> lote.dia end)
    |> Enum.uniq()
    |> length()
  end

  @doc "Calcula el descuento de alquiler para un confeccionista."
  def descuento_alquiler(confeccionista, lotes) do
    if confeccionista.alquiler do
      dias_trabajados(lotes) * Util.alquiler_diario()
    else
      0
    end
  end

  @doc "Calcula la liquidacion de un confeccionista usando lotes validos."
  def liquidar_confeccionista(confeccionista, lotes_validos) do
    lotes_persona =
      Enum.filter(lotes_validos, fn lote ->
        lote.confeccionista == confeccionista.codigo
      end)

    prendas =
      Enum.reduce(lotes_persona, 0, fn lote, total_prendas ->
        total_prendas + lote.prendas
      end)

    bruto =
      Enum.reduce(lotes_persona, 0, fn lote, total_bruto ->
        total_bruto + valor_lote(lote)
      end)

    prendas_diarias = prendas_por_confeccionista_y_dia(lotes_persona)
    bonificaciones = bonificaciones_confeccionista(confeccionista.codigo, prendas_diarias)
    alquiler = descuento_alquiler(confeccionista, lotes_persona)
    neto = bruto + bonificaciones - alquiler

    %{
      codigo: confeccionista.codigo,
      nombre: confeccionista.nombre,
      prendas: prendas,
      bruto: bruto,
      bonificaciones: bonificaciones,
      alquiler: alquiler,
      neto: neto
    }
  end

  @doc "Calcula la liquidacion de todos los confeccionistas."
  def liquidar_todos(confeccionistas, lotes_validos) do
    Enum.map(confeccionistas, fn confeccionista ->
      liquidar_confeccionista(confeccionista, lotes_validos)
    end)
  end
end
