defmodule Datos do
  @moduledoc """
  Contiene los confeccionistas, las lineas de produccion y los lotes del taller.
  """

  @doc "Devuelve la lista de confeccionistas y si usan maquinas del taller."
  def confeccionistas do
    [
      %{codigo: "C01", nombre: "Maria Elena Rios", alquiler: true},
      %{codigo: "C02", nombre: "Andres Salazar", alquiler: false},
      %{codigo: "C03", nombre: "Laura Gomez", alquiler: true},
      %{codigo: "C04", nombre: "Carlos Ramirez", alquiler: false},
      %{codigo: "C05", nombre: "Diana Torres", alquiler: true},
      %{codigo: "C06", nombre: "Jorge Valencia", alquiler: false},
      %{codigo: "C07", nombre: "Paula Mejia", alquiler: true},
      %{codigo: "C08", nombre: "Santiago Lopez", alquiler: false},
      %{codigo: "C09", nombre: "Camila Herrera", alquiler: false},
      %{codigo: "C10", nombre: "Mateo Castro", alquiler: false}
    ]
  end


  @doc "Devuelve las lineas de produccion y sus puestos de trabajo."
  def lineas do
    [
      %{id: "L1", nombre: "Linea Norte", puestos: 6},
      %{id: "L2", nombre: "Linea Central", puestos: 4},
      %{id: "L3", nombre: "Linea Sur", puestos: 5},
      %{id: "L4", nombre: "Linea Oriente", puestos: 3}
    ]
  end

  @doc "Devuelve 80 lotes validos y dos lotes por cada motivo de rechazo."
  def lotes do
    lotes_validos =
      for confeccionista <- confeccionistas(), numero_lote <- 1..8 do
        %{
          confeccionista: confeccionista.codigo,
          linea: Enum.at(lineas(), rem(numero_lote - 1, length(lineas()))).id,
          dia: rem(numero_lote - 1, 6) + 1,
          prendas: 60 + numero_lote * 5,
          defectos: Enum.at([1.5, 3.0, 7.0, 12.0], rem(numero_lote - 1, 4))
        }
      end

    lotes_invalidos = [
      %{confeccionista: "C99", linea: "L1", dia: 1, prendas: 10, defectos: 0},
      %{confeccionista: "C98", linea: "L1", dia: 1, prendas: 10, defectos: 0},
      %{confeccionista: "C01", linea: "L99", dia: 1, prendas: 10, defectos: 0},
      %{confeccionista: "C02", linea: "L98", dia: 1, prendas: 10, defectos: 0},
      %{confeccionista: "C01", linea: "L1", dia: 0, prendas: 10, defectos: 0},
      %{confeccionista: "C02", linea: "L1", dia: 7, prendas: 10, defectos: 0},
      %{confeccionista: "C01", linea: "L1", dia: 1, prendas: 0, defectos: 0},
      %{confeccionista: "C02", linea: "L1", dia: 1, prendas: 181, defectos: 0},
      %{confeccionista: "C01", linea: "L1", dia: 1, prendas: 10, defectos: -1},
      %{confeccionista: "C02", linea: "L1", dia: 1, prendas: 10, defectos: 100.1}
    ]

    lotes_validos ++ lotes_invalidos
  end
end
