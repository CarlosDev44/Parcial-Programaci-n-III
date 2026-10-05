defmodule Reportes do
  @moduledoc """
  Calcula los datos que se presentan en los reportes del taller.
  """

  @motivos_rechazo [
    :confeccionista_desconocido,
    :linea_desconocida,
    :dia_invalido,
    :prendas_fuera_de_rango,
    :porcentaje_invalido
  ]

  @doc "R1: devuelve los lotes rechazados y el conteo de cada motivo."
  def reporte_rechazados(rechazados) do
    conteos_iniciales =
      Enum.reduce(@motivos_rechazo, %{}, fn motivo, conteos ->
        Map.put(conteos, motivo, 0)
      end)

    conteos =
      Enum.reduce(rechazados, conteos_iniciales, fn {_lote, motivo}, conteos ->
        Map.update(conteos, motivo, 1, fn cantidad -> cantidad + 1 end)
      end)

    %{rechazados: rechazados, conteos: conteos}
  end

  @doc "R2: devuelve la produccion y productividad por puesto de cada linea."
  def reporte_produccion_por_linea(lineas, lotes_validos) do
    lineas
    |> Enum.map(fn linea ->
      lotes_linea =
        Enum.filter(lotes_validos, fn lote ->
          lote.linea == linea.id
        end)

      prendas =
        Enum.reduce(lotes_linea, 0, fn lote, total_prendas ->
          total_prendas + lote.prendas
        end)

      %{
        id: linea.id,
        nombre: linea.nombre,
        puestos: linea.puestos,
        prendas: prendas,
        productividad: prendas / linea.puestos
      }
    end)
    |> Enum.sort_by(fn linea -> linea.productividad end, :desc)
  end

  @doc "R3: devuelve las prendas de cada dia y el cumplimiento de la meta diaria."
  def reporte_produccion_diaria(lotes_validos) do
    produccion_por_dia =
      Enum.map(Util.dias_produccion(), fn dia ->
        lotes_dia =
          Enum.filter(lotes_validos, fn lote ->
            lote.dia == dia
          end)

        prendas =
          Enum.reduce(lotes_dia, 0, fn lote, total_prendas ->
            total_prendas + lote.prendas
          end)

        %{
          dia: dia,
          prendas: prendas,
          meta_alcanzada?: prendas >= Util.meta_diaria()
        }
      end)

    %{
      dias: produccion_por_dia,
      meta_todos_los_dias?: Enum.all?(produccion_por_dia, fn dia -> dia.meta_alcanzada? end),
      meta_al_menos_un_dia?: Enum.any?(produccion_por_dia, fn dia -> dia.meta_alcanzada? end)
    }
  end

  @doc "R4: ordena las liquidaciones de mayor a menor pago neto."
  def reporte_liquidaciones(liquidaciones) do
    Enum.sort_by(liquidaciones, fn liquidacion -> liquidacion.neto end, :desc)
  end

  @doc "R5: devuelve los lideres por dia y quienes ocuparon mas dias el primer lugar."
  def reporte_mayores_productores(confeccionistas, lotes_validos) do
    prendas_por_dia = Liquidacion.prendas_por_confeccionista_y_dia(lotes_validos)

    produccion_diaria =
      Enum.map(Util.dias_produccion(), fn dia ->
        producciones_dia =
          Enum.filter(Map.to_list(prendas_por_dia), fn {{_codigo, dia_lote}, _prendas} ->
            dia_lote == dia
          end)

        maximo_prendas =
          Enum.reduce(producciones_dia, 0, fn {_clave, prendas}, maximo ->
            if prendas > maximo, do: prendas, else: maximo
          end)

        lideres =
          producciones_dia
          |> Enum.filter(fn {_clave, prendas} -> prendas == maximo_prendas and maximo_prendas > 0 end)
          |> Enum.map(fn {{codigo, _dia}, prendas} ->
            confeccionista =
              Enum.find(confeccionistas, fn persona ->
                persona.codigo == codigo
              end)

            %{codigo: codigo, nombre: confeccionista.nombre, prendas: prendas}
          end)

        %{
          dia: dia,
          prendas_maximas: maximo_prendas,
          sin_produccion?: lideres == [],
          lideres: lideres
        }
      end)

    veces_primero =
      Enum.reduce(produccion_diaria, %{}, fn dia, conteos ->
        Enum.reduce(dia.lideres, conteos, fn lider, conteos_dia ->
          Map.update(conteos_dia, lider.codigo, 1, fn cantidad -> cantidad + 1 end)
        end)
      end)

    maximo_dias_primero =
      if map_size(veces_primero) == 0 do
        0
      else
        Enum.max(Map.values(veces_primero))
      end

    primeros_mas_dias =
      veces_primero
      |> Enum.filter(fn {_codigo, cantidad} -> cantidad == maximo_dias_primero end)
      |> Enum.map(fn {codigo, cantidad} ->
        confeccionista =
          Enum.find(confeccionistas, fn persona ->
            persona.codigo == codigo
          end)

        %{codigo: codigo, nombre: confeccionista.nombre, dias: cantidad}
      end)

    %{
      dias: produccion_diaria,
      primeros_mas_dias: primeros_mas_dias,
      cantidad_dias_primero: maximo_dias_primero
    }
  end

  @doc "R6: encuentra la mejor calidad por defectos ponderados entre quienes tienen tres lotes."
  def reporte_mejor_calidad(confeccionistas, lotes_validos) do
    calidades =
      Enum.map(confeccionistas, fn confeccionista ->
        lotes_persona =
          Enum.filter(lotes_validos, fn lote ->
            lote.confeccionista == confeccionista.codigo
          end)

        if length(lotes_persona) >= 3 do
          total_prendas =
            Enum.reduce(lotes_persona, 0, fn lote, total ->
              total + lote.prendas
            end)

          defectos_ponderados =
            Enum.reduce(lotes_persona, 0, fn lote, total ->
              total + lote.defectos * lote.prendas
            end)

          %{
            codigo: confeccionista.codigo,
            nombre: confeccionista.nombre,
            porcentaje_ponderado: defectos_ponderados / total_prendas
          }
        else
          nil
        end
      end)
      |> Enum.reject(fn calidad -> is_nil(calidad) end)

    if calidades == [] do
      %{mejores: [], porcentaje_ponderado: nil}
    else
      mejor_porcentaje =
        Enum.min_by(calidades, fn calidad -> calidad.porcentaje_ponderado end).porcentaje_ponderado

      mejores =
        Enum.filter(calidades, fn calidad ->
          calidad.porcentaje_ponderado == mejor_porcentaje
        end)

      %{mejores: mejores, porcentaje_ponderado: mejor_porcentaje}
    end
  end

  @doc "R7: calcula el pago total y el costo promedio por prenda valida."
  def reporte_pago_total(liquidaciones) do
    total_pagado =
      Enum.reduce(liquidaciones, 0, fn liquidacion, total ->
        total + liquidacion.neto
      end)

    total_prendas =
      Enum.reduce(liquidaciones, 0, fn liquidacion, total ->
        total + liquidacion.prendas
      end)

    costo_promedio =
      if total_prendas == 0 do
        :no_calculable
      else
        total_pagado / total_prendas
      end

    %{
      total_pagado: total_pagado,
      prendas_validas: total_prendas,
      costo_promedio: costo_promedio
    }
  end

  @doc "R8: devuelve los confeccionistas con lotes validos en todas las lineas."
  def reporte_todas_las_lineas(confeccionistas, lineas, lotes_validos) do
    Enum.filter(confeccionistas, fn confeccionista ->
      lotes_persona =
        Enum.filter(lotes_validos, fn lote ->
          lote.confeccionista == confeccionista.codigo
        end)

      Enum.all?(lineas, fn linea ->
        Enum.any?(lotes_persona, fn lote ->
          lote.linea == linea.id
        end)
      end)
    end)
    |> Enum.map(fn confeccionista ->
      %{codigo: confeccionista.codigo, nombre: confeccionista.nombre}
    end)
  end

  @doc "Ordena liquidaciones por campo y sentido, con un limite opcional."
  def ranking(liquidaciones, opciones) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, :todos)

    limite_valido? = limite == :todos or (is_integer(limite) and limite > 0)

    if campo in [:neto, :prendas, :bruto] and orden in [:desc, :asc] and limite_valido? do
      liquidaciones_ordenadas =
        Enum.sort_by(liquidaciones, fn liquidacion -> Map.get(liquidacion, campo) end, orden)

      if limite == :todos do
        liquidaciones_ordenadas
      else
        Enum.take(liquidaciones_ordenadas, limite)
      end
    else
      {:error, :opciones_invalidas}
    end
  end

  @doc "Combina la produccion diaria de dos talleres sumando los dias compartidos."
  def combinar_produccion_diaria(produccion_taller, produccion_aliado) do
    Map.merge(produccion_taller, produccion_aliado, fn _dia, prendas_taller, prendas_aliado ->
      prendas_taller + prendas_aliado
    end)
  end
end
