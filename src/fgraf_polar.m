function fig = fgraf_polar(fileName)
%FGRAF_POLAR Abre en el dashboard una matriz PVGIS guardada en formato MAT.
% fgraf_polar('data/PVGIS_Béjar_40.387_-5.765.mat')
if nargin~=1||~(ischar(fileName)||isstring(fileName))
    error('pv:file','Indique la ruta de un archivo .mat.');
end
fig=pv_productividad_visualizador(char(fileName));
end
