# PVGIS Productividad – MATLAB Tools

Herramientas en MATLAB para:
- Consultar la API de **PVGIS** y generar cartas de **productividad** e **irradiación** anuales en función de inclinación (0–90°) y acimut (−170° a 180°).
- Dibujar gráficos polares y de contorno a partir de datos guardados para evitar llamadas repetidas a la API.

## Estructura del repositorio

```
.
├─ src/
│  ├─ fPVGIS.m        # Consulta PVGIS y guarda matrices (productividad, irradiación, pérdidas)
│  ├─ fgraf_polar.m   # Carga un .mat y genera 2 gráficos polares
│  └─ fpolar3.m       # Rutina de gráfico polar con ejes y etiquetas personalizadas
├─ data/
│  └─ PVGIS_Béjar_40.387_-5.765.mat  # Ejemplo de datos (puedes borrarlo si prefieres no versionar datos)
└─ examples/
   └─ demo.m          # Ejemplo mínimo de uso
```

> Nota: **fPVGIS.m** realiza 684 llamadas a la API (tiempo de ejecución de varios minutos) para rellenar la malla completa de ángulos. Si una consulta falla, muestra un aviso y guarda `NaN` en las cinco matrices para esa combinación de inclinación y acimut.

## Requisitos

- MATLAB R2020b o posterior (recomendado R2023+).
- Acceso a Internet (solo para `fPVGIS.m`).
- La función usa `webread` y el endpoint oficial de PVGIS (JRC, Comisión Europea).

## Uso rápido

### 1) Consultar PVGIS y guardar datos
```matlab
% Ejemplo: localidad, latitud, longitud
fPVGIS('Teruel', 40.380, -1.216);
% Esto generará un archivo .mat con:
%   productividad  irradiacion  perd_aoi  perd_esp  perd_temp  max_pro  max_irr  localidad
```

### 2) Graficar desde un .mat existente (sin llamar a la API)

```matlab
% Usar un fichero .mat ya generado (o el de data/)
fgraf_polar('data/PVGIS_Béjar_40.387_-5.765.mat');
```

### 3) Graficar una matriz propia con `fpolar3`

```matlab
% data: matriz (19x37 si es cada 5°x10°) con elevación 0–90° y acimut −170–180°
fpolar3(data, 'Etiqueta del radio', 'Localidad', 'Lat', 'Lon');
```

## Detalles de los ficheros

- **`src/fPVGIS.m`**
  - Entrada: `fPVGIS(localidad, latitud, longitud)`.
  - Salida (en fichero `.mat`): matrices `productividad`, `irradiacion`, `perd_aoi`, `perd_esp`, `perd_temp`; escalares `max_pro`, `max_irr`; cadena `localidad`.
  - Barridos:
    - Inclinación: `0:5:90` (19 valores).
    - Acimut: `-170:10:180` (36 valores).
  - Internamente llama a una función auxiliar que usa `webread` hacia la API de PVGIS.

- **`src/fgraf_polar.m`**
  - Entrada: nombre de archivo `.mat` con variables anteriores.
  - Dibuja:
    - Gráfico polar de `irradiacion` anual (kWh/m²).
    - Gráfico polar de `productividad` normalizada (%).

- **`src/fpolar3.m`**
  - Función de utilidad para representar matrices en coordenadas polares con 20 intervalos de color, ignorando valores `NaN` al calcular sus límites.
  - Muestra etiquetas de elevación entre 0° y 90° y etiquetas de acimut cada 15°.

## Buenas prácticas para datos

Si vas a guardar muchos `.mat` (p.ej., distintas ubicaciones), considera:
- Añadir `data/` a **.gitignore** o usar **Git LFS** para binarios grandes.
- Documentar la procedencia de los datos en `README.md` (fecha, parámetros).

## Citar PVGIS

Si utilizas estos datos en publicaciones, por favor cita PVGIS (JRC, European Commission) y la API PVGIS. Consulta la referencia oficial en:
- PVGIS website y documentación de la API: https://re.jrc.ec.europa.eu/pvg_tools/en/
- Publicaciones de referencia del JRC asociadas a PVGIS.

## Licencia

Este proyecto se publica bajo **MIT** (ver `LICENSE`).

## Contribuir

- Abre un *issue* o *pull request*.
- Revisa `CONTRIBUTING.md` y el `CODE_OF_CONDUCT.md`.

---

© 2025 Esteban Sánchez
