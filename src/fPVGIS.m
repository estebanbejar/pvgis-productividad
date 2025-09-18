% Calculo de la carta de productividad y de irradiación anuales utilizando
% la API de PVGIS
% Ejemplo: fPVGIS('Teruel',40.380,-1.216);

% Importante: Las 684 llamadas a la API para formar la matriz hacen que el
% proceso necesite varios minutos para completarse


function fPVGIS(localidad,latitud,longitud)

% Barrido en inclinación y acimut
i=1;
a=1;
for inclinacion=0:5:90
    for acimut=-170:10:180
        % Llamada a la función PVGIS1, que hace la consulta mediantes la
        % API de PVGIS
        [productividad(i,a), irradiacion(i,a), perd_aoi(i,a),perd_esp(i,a),perd_temp(i,a)]=fPVGIS1(latitud,longitud,inclinacion,acimut);
        a=a+1;
    end
    a=1;
    i=i+1;
end
i=1;
% Valores máximos
max_pro=max(productividad,[],'all');
max_irr=max(irradiacion,[],'all');

% Guardar datos
% save (['PVGIS_',localidad,'_',num2str(latitud),'_',num2str(longitud),'.mat'],'localidad','productividad','irradiacion','max_pro','max_irr','perd_temp','perd_esp','perd_aoi');
fileName=['PVGIS_',localidad,'_',num2str(latitud),'_',num2str(longitud),'.mat'];
save (fileName,'localidad','productividad','irradiacion','max_pro','max_irr','perd_temp','perd_esp','perd_aoi');
%fpolar3(fileName);

% Gráficas

fmalla(irradiacion,[localidad,'. Irradiación anual (kWh/m^2)'])
fmalla(productividad*100/max_pro,[localidad,'. Productividad (%)']); % En porcentaje

fpolar3(irradiacion,'Irradiación anual (kWh/m^2)',localidad,latitud,longitud);
fpolar3(productividad*100/max_pro,'Productividad (%)',localidad,latitud,longitud);
end

% Función para obtener datos de producción solar desde la API de PVGIS
% Creado con ayuda de chatGPT4

function [productividad, irradiacion, perd_aoi,perd_esp,perd_temp]=fPVGIS1(latitud,longitud,inclinacion,acimut)

% Definir la URL base de la API de PVGIS
url_base = 'https://re.jrc.ec.europa.eu/api/v5_2/PVcalc';

% Crear la URL de la solicitud con los parámetros necesarios
url = sprintf('%s?lat=%f&lon=%f&peakpower=1&loss=14&angle=%f&aspect=%f&outputformat=json', ...
              url_base, latitud, longitud, inclinacion, acimut);

% Mostrar la URL de la solicitud (opcional para verificar)
%disp(['Solicitando datos a: ', url]);

% Realizar la solicitud a la API
datos = webread(url);

if isfield(datos, 'outputs')
    productividad=datos.outputs.totals.fixed.E_y;
    irradiacion=datos.outputs.totals.fixed.H_i__y;
    perd_aoi=datos.outputs.totals.fixed.l_aoi;
    perd_esp=str2num(datos.outputs.totals.fixed.l_spec);
    perd_temp=datos.outputs.totals.fixed.l_tg;

end
end

% Crear grafico de superficies

function fmalla(productividad,etiqueta)

figure;
B = rot90(productividad,2);
% Crear una malla para los ejes X e Y
eje_x=-170:10:180;
eje_y=90:-5:0;
[X, Y] = meshgrid(eje_x, eje_y);

% Gráfico de superficie
contourf(X, Y, B,20);
grid;grid minor;

% Añadir etiquetas y título
xlabel('Acimut');
ylabel('Inclinación');
title(etiqueta);
%title('Productividad (%)');
colorbar;  % Añadir barra de color para representar la magnitud de los valores

end