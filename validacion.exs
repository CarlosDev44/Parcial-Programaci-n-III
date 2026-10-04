defmodule Validacion do
  @moduledoc """
  Valida los lotes de produccion segun las reglas del taller.
  """

  @doc "Valida un lote en el orden establecido y devuelve su resultado."
  def validar_lote(lote, confeccionistas, lineas) do
    with :ok <- validar_confeccionista(lote, confeccionistas),
         :ok <- validar_linea(lote, lineas),
         :ok <- validar_dia(lote),
         :ok <- validar_prendas(lote),
         :ok <- validar_porcentaje(lote) do
      {:ok, lote}
    end
  end

  defp validar_confeccionista(lote, confeccionistas) do
    codigo = Map.get(lote, :confeccionista)

    if Enum.any?(confeccionistas, fn confeccionista ->
         confeccionista.codigo == codigo
       end) do
      :ok
    else
      {:error, :confeccionista_desconocido}
    end
  end

  defp validar_linea(lote, lineas) do
    id_linea = Map.get(lote, :linea)

    if Enum.any?(lineas, fn linea -> linea.id == id_linea end) do
      :ok
    else
      {:error, :linea_desconocida}
    end
  end

  defp validar_dia(lote) do
    dia = Map.get(lote, :dia)

    if is_integer(dia) and Enum.member?(Util.dias_produccion(), dia) do
      :ok
    else
      {:error, :dia_invalido}
    end
  end

  defp validar_prendas(lote) do
    prendas = Map.get(lote, :prendas)

    if is_integer(prendas) and prendas >= 1 and prendas <= Util.maximo_prendas_lote() do
      :ok
    else
      {:error, :prendas_fuera_de_rango}
    end
  end

  defp validar_porcentaje(lote) do
    defectos = Map.get(lote, :defectos)

    if is_number(defectos) and defectos >= 0 and defectos <= 100 do
      :ok
    else
      {:error, :porcentaje_invalido}
    end
  end
end
