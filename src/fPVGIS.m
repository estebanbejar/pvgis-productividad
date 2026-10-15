function fig = fPVGIS(varargin)
%FPVGIS Abre el dashboard de productividad e irradiación PVGIS.
% fPVGIS
% fPVGIS(localidad,latitud,longitud) abre el dashboard con ubicación inicial.
if nargin==0
    fig=pv_productividad_visualizador();
elseif nargin==3
    fig=pv_productividad_visualizador(varargin{:});
else
    error('pv:usage','Use fPVGIS o fPVGIS(localidad,latitud,longitud).');
end
end
