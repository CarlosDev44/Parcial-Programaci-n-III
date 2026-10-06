# Liquidacion de produccion del taller

Aplicacion de consola escrita en Elixir para validar lotes de produccion, calcular liquidaciones y mostrar los reportes R1-R8.

## Requisitos

- Elixir y Erlang/OTP instalados.
- Ejecutar los comandos desde esta carpeta.
- No se utiliza Mix ni librerias externas.

## Compilar

En PowerShell, compila los modulos de apoyo en este orden:

```powershell
elixirc .\util.exs
elixirc .\datos.exs
elixirc -pa . .\validacion.exs
elixirc -pa . .\liquidacion.exs
elixirc -pa . .\reportes.exs
```

La compilacion genera los archivos `.beam` en esta carpeta. Si modificas un modulo de apoyo, vuelve a ejecutar su comando de compilacion antes de iniciar el programa.

## Ejecutar

```powershell
elixir .\programa.ex
```

El programa solicita un lote adicional o Enter para omitirlo; despues de los reportes, solicita el codigo para el comprobante individual.

> El enunciado original menciona `programa.exs`. En este proyecto, el archivo principal se llama `programa.ex`, por lo que el comando de ejecucion usa esa extension.
