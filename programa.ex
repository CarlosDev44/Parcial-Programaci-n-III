#Carlos Arturo Moreno Arroyave
#Santiago Padilla Espinosa
#Julian David Patiño

defmodule Programa do
  @moduledoc """
  Coordina la validacion, liquidacion, reportes e interaccion por consola.
  """

  @doc "Ejecuta el flujo principal del programa."
  def main do
    confeccionistas = Datos.confeccionistas()
    lineas = Datos.lineas()
    lotes = Datos.lotes()

    {lotes_validos, lotes_rechazados} =
      clasificar_lotes(lotes, confeccionistas, lineas)

    {lotes_validos, lotes_rechazados} =
      solicitar_lote_adicional(lotes_validos, lotes_rechazados, confeccionistas, lineas)

    liquidaciones = Liquidacion.liquidar_todos(confeccionistas, lotes_validos)

    imprimir_reportes(
      confeccionistas,
      lineas,
      lotes_validos,
      lotes_rechazados,
      liquidaciones
    )

    imprimir_rankings(liquidaciones)
    solicitar_comprobante(confeccionistas, lotes_validos)
  end

  defp clasificar_lotes(lotes, confeccionistas, lineas) do
    {validos, rechazados} =
      Enum.reduce(lotes, {[], []}, fn lote, {lotes_validos, lotes_rechazados} ->
        case Validacion.validar_lote(lote, confeccionistas, lineas) do
          {:ok, lote_valido} ->
            {[lote_valido | lotes_validos], lotes_rechazados}

          {:error, motivo} ->
            {lotes_validos, [{lote, motivo} | lotes_rechazados]}
        end
      end)

    {Enum.reverse(validos), Enum.reverse(rechazados)}
  end

  defp solicitar_lote_adicional(lotes_validos, lotes_rechazados, confeccionistas, lineas) do
    entrada =
      IO.gets("Ingrese un lote adicional (confeccionista;linea;dia;prendas;defectos) o Enter para omitir: ")

    case entrada do
      nil ->
        IO.puts("Lote adicional omitido.")
        {lotes_validos, lotes_rechazados}

      linea_ingresada ->
        if String.trim(linea_ingresada) == "" do
          IO.puts("Lote adicional omitido.")
          {lotes_validos, lotes_rechazados}
        else
          procesar_lote_adicional(
            String.trim(linea_ingresada),
            lotes_validos,
            lotes_rechazados,
            confeccionistas,
            lineas
          )
        end
    end
  end

  defp procesar_lote_adicional(entrada, lotes_validos, lotes_rechazados, confeccionistas, lineas) do
    case parsear_lote_adicional(entrada) do
      {:ok, lote} ->
        case Validacion.validar_lote(lote, confeccionistas, lineas) do
          {:ok, lote_valido} ->
            IO.puts("Lote adicional agregado.")
            {lotes_validos ++ [lote_valido], lotes_rechazados}

          {:error, motivo} ->
            IO.puts("Lote adicional rechazado: #{inspect(motivo)}.")
            {lotes_validos, lotes_rechazados ++ [{lote, motivo}]}
        end

      {:error, :formato_invalido} ->
        IO.puts("Lote adicional rechazado: formato invalido.")
        {lotes_validos, lotes_rechazados}
    end
  end

  defp parsear_lote_adicional(entrada) do
    case String.split(entrada, ";") do
      [codigo, linea, dia_texto, prendas_texto, defectos_texto] ->
        with {:ok, dia} <- parsear_entero(dia_texto),
             {:ok, prendas} <- parsear_entero(prendas_texto),
             {:ok, defectos} <- parsear_numero(defectos_texto) do
          {:ok,
           %{
             confeccionista: String.trim(codigo),
             linea: String.trim(linea),
             dia: dia,
             prendas: prendas,
             defectos: defectos
           }}
        else
          _ -> {:error, :formato_invalido}
        end

      _ ->
        {:error, :formato_invalido}
    end
  end

  defp parsear_entero(texto) do
    case Integer.parse(String.trim(texto)) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end

  defp parsear_numero(texto) do
    case Float.parse(String.trim(texto)) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end

  defp imprimir_reportes(confeccionistas, lineas, lotes_validos, lotes_rechazados, liquidaciones) do
    imprimir_reporte_r1(lotes_rechazados)
    imprimir_reporte_r2(lineas, lotes_validos)
    imprimir_reporte_r3(lotes_validos)
    imprimir_reporte_r4(liquidaciones)
    imprimir_reporte_r5(confeccionistas, lotes_validos)
    imprimir_reporte_r6(confeccionistas, lotes_validos)
    imprimir_reporte_r7(liquidaciones)
    imprimir_reporte_r8(confeccionistas, lineas, lotes_validos)
  end

  defp imprimir_reporte_r1(lotes_rechazados) do
    IO.puts("\nR1 - Lotes rechazados")
    reporte = Reportes.reporte_rechazados(lotes_rechazados)

    Enum.each(reporte.rechazados, fn {lote, motivo} ->
      IO.puts("  #{inspect(lote)} -> #{inspect(motivo)}")
    end)

    IO.puts("Cantidad por motivo:")

    Enum.each(reporte.conteos, fn {motivo, cantidad} ->
      IO.puts("  #{inspect(motivo)}: #{cantidad}")
    end)
  end

  defp imprimir_reporte_r2(lineas, lotes_validos) do
    IO.puts("\nR2 - Produccion y productividad por linea")

    lineas
    |> Reportes.reporte_produccion_por_linea(lotes_validos)
    |> Enum.each(fn linea ->
      IO.puts(
        "  #{linea.nombre}: #{linea.prendas} prendas, #{linea.puestos} puestos, " <>
          "#{Float.to_string(linea.productividad)} prendas por puesto"
      )
    end)
  end

  defp imprimir_reporte_r3(lotes_validos) do
    IO.puts("\nR3 - Produccion diaria y meta")
    reporte = Reportes.reporte_produccion_diaria(lotes_validos)

    Enum.each(reporte.dias, fn dia ->
      IO.puts(
        "  Dia #{dia.dia}: #{dia.prendas} prendas; meta " <>
          "#{if dia.meta_alcanzada?, do: "alcanzada", else: "no alcanzada"}"
      )
    end)

    IO.puts("  Meta alcanzada todos los dias: #{si_no(reporte.meta_todos_los_dias?)}")
    IO.puts("  Meta alcanzada al menos un dia: #{si_no(reporte.meta_al_menos_un_dia?)}")
  end

  defp imprimir_reporte_r4(liquidaciones) do
    IO.puts("\nR4 - Liquidacion semanal")

    liquidaciones
    |> Reportes.reporte_liquidaciones()
    |> Enum.with_index(1)
    |> Enum.each(fn {liquidacion, numero} ->
      IO.puts(
        "  #{numero}. #{liquidacion.nombre} (#{liquidacion.codigo}): " <>
          "#{liquidacion.prendas} prendas; lotes #{formatear_dinero(liquidacion.bruto)}; " <>
          "bonificaciones #{formatear_dinero(liquidacion.bonificaciones)}; " <>
          "alquiler #{formatear_dinero(liquidacion.alquiler)}; neto #{formatear_dinero(liquidacion.neto)}"
      )
    end)
  end

  defp imprimir_reporte_r5(confeccionistas, lotes_validos) do
    IO.puts("\nR5 - Mayores productores por dia")
    reporte = Reportes.reporte_mayores_productores(confeccionistas, lotes_validos)

    Enum.each(reporte.dias, fn dia ->
      if dia.sin_produccion? do
        IO.puts("  Dia #{dia.dia}: sin produccion")
      else
        Enum.each(dia.lideres, fn lider ->
          IO.puts("  Dia #{dia.dia}: #{lider.nombre} (#{lider.codigo}), #{lider.prendas} prendas")
        end)
      end
    end)

    if reporte.primeros_mas_dias == [] do
      IO.puts("  No hubo dias con produccion.")
    else
      IO.puts("  Primer lugar mas dias (#{reporte.cantidad_dias_primero}):")

      Enum.each(reporte.primeros_mas_dias, fn persona ->
        IO.puts("    #{persona.nombre} (#{persona.codigo})")
      end)
    end
  end

  defp imprimir_reporte_r6(confeccionistas, lotes_validos) do
    IO.puts("\nR6 - Mejor calidad")
    reporte = Reportes.reporte_mejor_calidad(confeccionistas, lotes_validos)

    if reporte.mejores == [] do
      IO.puts("  Nadie tiene al menos tres lotes validos.")
    else
      Enum.each(reporte.mejores, fn persona ->
        porcentaje = :erlang.float_to_binary(persona.porcentaje_ponderado, decimals: 2)

        IO.puts("  #{persona.nombre} (#{persona.codigo}): #{porcentaje}%")
      end)
    end
  end

  defp imprimir_reporte_r7(liquidaciones) do
    IO.puts("\nR7 - Total pagado y costo promedio por prenda")
    reporte = Reportes.reporte_pago_total(liquidaciones)
    IO.puts("  Total pagado: #{formatear_dinero(reporte.total_pagado)}")

    if reporte.costo_promedio == :no_calculable do
      IO.puts("  No hay prendas validas; el promedio no puede calcularse.")
    else
      IO.puts("  Prendas validas: #{reporte.prendas_validas}")
      IO.puts("  Costo promedio: #{formatear_dinero(reporte.costo_promedio)} por prenda")
    end
  end

  defp imprimir_reporte_r8(confeccionistas, lineas, lotes_validos) do
    IO.puts("\nR8 - Confeccionistas con produccion en todas las lineas")
    personas = Reportes.reporte_todas_las_lineas(confeccionistas, lineas, lotes_validos)

    if personas == [] do
      IO.puts("  Ninguno.")
    else
      Enum.each(personas, fn persona ->
        IO.puts("  #{persona.nombre} (#{persona.codigo})")
      end)
    end
  end

  defp imprimir_rankings(liquidaciones) do
    IO.puts("\nRankings solicitados")
    IO.inspect(Reportes.ranking(liquidaciones, []), label: "Ranking por neto")

    IO.inspect(
      Reportes.ranking(liquidaciones, campo: :prendas, limite: 3),
      label: "Tres primeros por prendas"
    )

    IO.inspect(
      Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto),
      label: "Ranking ascendente por bruto"
    )
  end

  defp solicitar_comprobante(confeccionistas, lotes_validos) do
    codigo = IO.gets("\nIngrese el codigo del confeccionista para el comprobante: ")

    case codigo do
      nil ->
        IO.puts("No se recibio un codigo.")

      codigo_ingresado ->
        mostrar_comprobante(String.trim(codigo_ingresado), confeccionistas, lotes_validos)
    end
  end

  defp mostrar_comprobante(codigo, confeccionistas, lotes_validos) do
    confeccionista =
      Enum.find(confeccionistas, fn persona ->
        persona.codigo == codigo
      end)

    if confeccionista == nil do
      IO.puts("No existe un confeccionista con ese codigo.")
    else
      lotes_persona =
        Enum.filter(lotes_validos, fn lote ->
          lote.confeccionista == codigo
        end)

      liquidacion = Liquidacion.liquidar_confeccionista(confeccionista, lotes_persona)
      IO.puts("\nComprobante individual")
      IO.puts("  Nombre: #{confeccionista.nombre}")
      IO.puts("  Codigo: #{confeccionista.codigo}")
      imprimir_detalle_diario(lotes_persona)

      IO.puts("  Suma de lotes: #{formatear_dinero(liquidacion.bruto)}")
      IO.puts("  Suma de bonificaciones: #{formatear_dinero(liquidacion.bonificaciones)}")
      IO.puts("  Descuento por alquiler: #{formatear_dinero(liquidacion.alquiler)}")
      IO.puts("  Neto: #{formatear_dinero(liquidacion.neto)}")
    end
  end

  defp imprimir_detalle_diario(lotes_persona) do
    Enum.each(Util.dias_produccion(), fn dia ->
      lotes_dia = Enum.filter(lotes_persona, fn lote -> lote.dia == dia end)

      if lotes_dia != [] do
        prendas = sumar_prendas(lotes_dia)
        valor_lotes = sumar_valores_lotes(lotes_dia)
        bonificacion = Liquidacion.bono_diario(prendas)

        IO.puts(
          "  Dia #{dia}: #{prendas} prendas; lotes #{formatear_dinero(valor_lotes)}; " <>
            "bonificacion #{formatear_dinero(bonificacion)}"
        )
      end
    end)
  end

  defp sumar_prendas(lotes) do
    Enum.reduce(lotes, 0, fn lote, total -> total + lote.prendas end)
  end

  defp sumar_valores_lotes(lotes) do
    Enum.reduce(lotes, 0, fn lote, total -> total + Liquidacion.valor_lote(lote) end)
  end

  defp formatear_dinero(valor) do
    "$" <> :erlang.float_to_binary(valor * 1.0, decimals: 2)
  end

  defp si_no(true), do: "si"
  defp si_no(false), do: "no"
end

Programa.main()
