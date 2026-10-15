function r = pv_productividad_calcular(localidad,latitud,longitud,progressFcn)
%PV_PRODUCTIVIDAD_CALCULAR Consulta PVGIS para la malla anual de orientación.
% r = pv_productividad_calcular(nombre,latitud,longitud,progressFcn)
% La malla contiene inclinaciones 0:5:90 y acimuts -170:10:180.
if nargin<4,progressFcn=[];end
if isstring(localidad),localidad=char(localidad);end
if ~ischar(localidad)||isempty(strtrim(localidad)),error('pv:location','Indique un nombre de localidad.');end
validateattributes(latitud,{'numeric'},{'scalar','real','finite','>=',-90,'<=',90});
validateattributes(longitud,{'numeric'},{'scalar','real','finite','>=',-180,'<=',180});

inclinaciones=0:5:90;acimuts=-170:10:180;
productividad=nan(numel(inclinaciones),numel(acimuts));
irradiacion=productividad;perd_aoi=productividad;perd_esp=productividad;perd_temp=productividad;
n=0;fallos=0;total=numel(productividad);
for i=1:numel(inclinaciones)
    for j=1:numel(acimuts)
        n=n+1;
        try
            [productividad(i,j),irradiacion(i,j),perd_aoi(i,j),perd_esp(i,j),perd_temp(i,j)]= ...
                consultaPVGIS(latitud,longitud,inclinaciones(i),acimuts(j));
            if isnan(productividad(i,j))||isnan(irradiacion(i,j)),fallos=fallos+1;end
        catch
            fallos=fallos+1;
        end
        if ~isempty(progressFcn)
            continuar=progressFcn(n,total,fallos);
            if isequal(continuar,false),error('pv:cancelled','Consulta cancelada por el usuario.');end
        end
    end
end
if all(isnan(productividad),'all')||all(isnan(irradiacion),'all')
    error('pv:noData','PVGIS no devolvió resultados válidos. Compruebe la conexión y vuelva a intentarlo.');
end
max_pro=max(productividad,[],'all','omitnan');
max_irr=max(irradiacion,[],'all','omitnan');
r=struct('localidad',strtrim(localidad),'latitud',latitud,'longitud',longitud, ...
    'lat',latitud,'lon',longitud,'productividad',productividad,'irradiacion',irradiacion, ...
    'perd_aoi',perd_aoi,'perd_esp',perd_esp,'perd_temp',perd_temp, ...
    'max_pro',max_pro,'max_irr',max_irr,'inclinaciones',inclinaciones,'acimuts',acimuts, ...
    'fecha_consulta',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
end

function [ey,hi,laoi,lspec,ltg]=consultaPVGIS(lat,lon,angle,aspect)
url=sprintf(['https://re.jrc.ec.europa.eu/api/v5_2/PVcalc?lat=%.6f&lon=%.6f&peakpower=1' ...
    '&loss=14&angle=%.1f&aspect=%.1f&outputformat=json'],lat,lon,angle,aspect);
data=webread(url,weboptions('Timeout',30));
fixed=data.outputs.totals.fixed;
ey=fixed.E_y;hi=fixed.H_i__y;laoi=fixed.l_aoi;
lspec=valorNumerico(fixed.l_spec);ltg=fixed.l_tg;
end

function x=valorNumerico(x)
if ischar(x)||isstring(x),x=str2double(x);end
if isempty(x)||~isnumeric(x)||~isscalar(x)||~isfinite(x),x=NaN;end
end
