#Carlos Arturo Moreno Arroyave
#Santiago Padilla Espinosa
#Julian David Patiño

defmodule Util do
  @moduledoc """
  Contiene las constantes del taller y funciones para consultarlas.
  """

  @tarifa_base 3200
  @meta_diaria 600
  @dias_produccion 1..6
  @maximo_prendas_lote 180
  @umbral_bonificacion 120
  @bonificacion_diaria 18000
  @alquiler_diario 15000

  @doc "Devuelve la tarifa base por prenda."
  def tarifa_base do
    @tarifa_base
  end

  @doc "Devuelve la meta diaria de produccion del taller."
  def meta_diaria do
    @meta_diaria
  end

  @doc "Devuelve el rango de dias de produccion."
  def dias_produccion do
    @dias_produccion
  end

  @doc "Devuelve la cantidad maxima de prendas permitida por lote."
  def maximo_prendas_lote do
    @maximo_prendas_lote
  end

  @doc "Devuelve el umbral diario de prendas para obtener el bono."
  def umbral_bonificacion do
    @umbral_bonificacion
  end

  @doc "Devuelve el valor del bono diario por productividad."
  def bonificacion_diaria do
    @bonificacion_diaria
  end

  @doc "Devuelve el valor del alquiler de maquina por dia trabajado."
  def alquiler_diario do
    @alquiler_diario
  end
end
