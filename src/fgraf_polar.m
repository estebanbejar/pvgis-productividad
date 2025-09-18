% Función para hacer las gráficas polares a partir de un fichero de datos y
% evitar la llamada a PVGIS (lenta)
% Ejemplo
% fgraf_polar ( 'PVGIS_Estocolmo_59.321_18.042.mat');

function fgraf_polar(fileName)

load (fileName);
[~, name, ~] = fileparts(fileName);
parts = strsplit(name, '_');
localidad = parts{2};
latitud   = parts{3};
longitud  = parts{4};

fpolar3(irradiacion,'Irradiación anual (kWh/m^2)',localidad,latitud,longitud);
fpolar3(productividad*100/max_pro,'Productividad (%)',localidad,latitud,longitud);
end