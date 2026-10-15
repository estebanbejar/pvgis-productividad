function fig = pv_productividad_visualizador(varargin)
%PV_PRODUCTIVIDAD_VISUALIZADOR Dashboard de productividad e irradiación PVGIS.
% pv_productividad_visualizador
% pv_productividad_visualizador(nombre,latitud,longitud)
% pv_productividad_visualizador(archivoMat)

nombreInicial='Punto seleccionado';latInicial=40;lonInicial=-5;archivoInicial='';
if nargin==1
    archivoInicial=char(varargin{1});
elseif nargin==3
    nombreInicial=char(varargin{1});latInicial=varargin{2};lonInicial=varargin{3};
elseif nargin~=0
    error('pv:usage','Use pv_productividad_visualizador, (nombre,latitud,longitud) o (archivoMat).');
end
fig=uifigure('Name','Productividad fotovoltaica · PVGIS','Position',[60 60 1450 860]);
outer=uigridlayout(fig,[2 1]);outer.RowHeight={70,'1x'};outer.Padding=[14 12 14 12];outer.RowSpacing=8;
header=uigridlayout(outer,[1 2]);header.ColumnWidth={210,'1x'};header.Padding=[0 0 0 0];
root=fileparts(fileparts(mfilename('fullpath')));
uiimage(header,'ImageSource',fullfile(root,'assets','usal.png'),'ScaleMethod','fit');
uilabel(header,'Text',{'Escuela Técnica Superior de Ingeniería Industrial · Área de Tecnología Electrónica', ...
    'Cartas anuales de irradiación y producción fotovoltaica · PVGIS'}, ...
    'FontSize',18,'FontWeight','bold','FontColor',[.09 .20 .31]);
body=uigridlayout(outer,[1 2]);body.ColumnWidth={315,'1x'};body.ColumnSpacing=14;
ctrl=uigridlayout(body,[13 2]);ctrl.ColumnWidth={105,'1x'};ctrl.RowHeight={25,32,25,32,25,32,42,42,42,30,30,70,'1x'};ctrl.RowSpacing=6;ctrl.Padding=[4 4 4 4];
uilabel(ctrl,'Text','Localidad');location=uieditfield(ctrl,'text','Value',nombreInicial,'Tag','locationName');
uilabel(ctrl,'Text','Latitud (°)');lat=uieditfield(ctrl,'numeric','Value',latInicial,'Limits',[-90 90],'Tag','latitude');
uilabel(ctrl,'Text','Longitud (°)');lon=uieditfield(ctrl,'numeric','Value',lonInicial,'Limits',[-180 180],'Tag','longitude');
mapButton=uibutton(ctrl,'Text','Seleccionar en mapa…','Tag','selectLocation','ButtonPushedFcn',@selectLocation);mapButton.Layout.Column=[1 2];
calcButton=uibutton(ctrl,'Text','Calcular carta PVGIS','FontWeight','bold','ButtonPushedFcn',@calculate);calcButton.Layout.Column=[1 2];
openButton=uibutton(ctrl,'Text','Abrir datos .mat','ButtonPushedFcn',@openMat);openButton.Layout.Column=[1 2];
saveButton=uibutton(ctrl,'Text','Guardar datos .mat','Enable','off','ButtonPushedFcn',@saveMat);saveButton.Layout.Column=[1 2];
uilabel(ctrl,'Text','Magnitud');metric=uidropdown(ctrl,'Items',{'Irradiación anual','Producción anual'}, ...
    'Value','Producción anual','Tag','metric');
uilabel(ctrl,'Text','Escala');scale=uidropdown(ctrl,'Items',{'Valor absoluto','Porcentaje del máximo'}, ...
    'Value','Porcentaje del máximo','Tag','scale');
summary=uilabel(ctrl,'Text','Elija una localidad, introduzca coordenadas y calcule la carta.','WordWrap','on','Tag','summary');summary.Layout.Column=[1 2];
note=uilabel(ctrl,'Text',sprintf(['Producción: kWh/kWp/año. Irradiación: kWh/m²/año.\n' ...
    'La escala tiene 20 bandas de 5% del máximo. El porcentaje en producción equivale a productividad.']), ...
    'WordWrap','on','FontColor',[.30 .36 .40]);note.Layout.Column=[1 2];
tabs=uitabgroup(body);cartTab=uitab(tabs,'Title','Carta cartesiana');polarTab=uitab(tabs,'Title','Carta polar');
cartGrid=uigridlayout(cartTab,[1 1]);cartAx=uiaxes(cartGrid);cartAx.Tag='cartesianAxes';
polarGrid=uigridlayout(polarTab,[1 1]);polarAx=uiaxes(polarGrid);polarAx.Tag='polarAxes';
status=uilabel(ctrl,'Text','','WordWrap','on');status.Layout.Column=[1 2];
result=[];cbCart=[];cbPolar=[];busy=false;dlg=[];
metric.ValueChangedFcn=@redraw;scale.ValueChangedFcn=@redraw;
lat.ValueChangedFcn=@locationEdited;lon.ValueChangedFcn=@locationEdited;location.ValueChangedFcn=@locationEdited;
fig.CloseRequestFcn=@(~,~)delete(fig);
if ~isempty(archivoInicial),loadMat(archivoInicial);end

    function selectLocation(varargin)
        if busy,return;end
        [newLat,newLon,ok,newName]=seleccionar_ubicacion(lat.Value,lon.Value, ...
            Nombre=string(location.Value));
        if ok&&isvalid(fig)
            lat.Value=newLat;lon.Value=newLon;location.Value=newName;
            status.Text='Ubicación seleccionada. Pulse Calcular carta PVGIS.';
        end
    end
    function locationEdited(varargin)
        if ~isempty(result)
            status.Text='Se han editado los datos de ubicación. La carta mostrada corresponde a la consulta anterior.';
        end
    end
    function calculate(varargin)
        if busy,return;end
        busy=true;setButtons('off');status.Text='Consultando PVGIS. La malla requiere hasta 684 consultas…';drawnow;
        dlg=uiprogressdlg(fig,'Title','Consulta PVGIS','Message','Preparando consulta…','Indeterminate','off', ...
            'Value',0,'Cancelable','on');
        try
            fresh=pv_productividad_calcular(location.Value,lat.Value,lon.Value,@updateProgress);
            result=fresh;saveButton.Enable='on';
            status.Text=sprintf('Consulta completada: %d de %d puntos válidos. Puede guardar la matriz en un archivo .mat.', ...
                nnz(isfinite(result.productividad)&isfinite(result.irradiacion)),numel(result.productividad));
            redraw();
        catch err
            if strcmp(err.identifier,'pv:cancelled')
                status.Text='Consulta cancelada. Los resultados anteriores se conservan.';
            else
                status.Text=['No se pudo completar la consulta: ' err.message];
            end
            if ~strcmp(err.identifier,'pv:cancelled')&&isvalid(fig),uialert(fig,err.message,'Consulta PVGIS');end
        end
        finishCalculate();
    end
    function keepGoing=updateProgress(done,total,failures)
        if ~isvalid(dlg),keepGoing=false;return;end
        dlg.Value=done/total;dlg.Message=sprintf('Consulta %d de %d · errores de consulta: %d',done,total,failures);
        drawnow limitrate;keepGoing=~dlg.CancelRequested;
    end
    function finishCalculate()
        busy=false;if isvalid(fig),setButtons('on');end
        if exist('dlg','var')&&isvalid(dlg),delete(dlg);end
    end
    function setButtons(state)
        calcButton.Enable=state;openButton.Enable=state;mapButton.Enable=state;
        if ~isempty(result),saveButton.Enable=state;end
    end
    function openMat(varargin)
        [file,folder]=uigetfile({'*.mat','Archivos MATLAB (*.mat)'},'Abrir carta guardada');
        if isequal(file,0),return;end
        loadMat(fullfile(folder,file));
    end
    function loadMat(file)
        try
            s=load(file);fresh=validarDatos(s,file);
            result=fresh;location.Value=fresh.localidad;lat.Value=fresh.latitud;lon.Value=fresh.longitud;
            saveButton.Enable='on';status.Text=['Datos cargados: ' file];redraw();
        catch err
            uialert(fig,err.message,'Archivo no válido');
        end
    end
    function saveMat(varargin)
        if isempty(result),return;end
        safe=regexprep(result.localidad,'[^\w-]','_');
        suggestion=sprintf('PVGIS_%s_%.3f_%.3f.mat',safe,result.latitud,result.longitud);
        [file,folder]=uiputfile({'*.mat','Datos MATLAB (*.mat)'},'Guardar datos de la carta',suggestion);
        if isequal(file,0),return;end
        try
            data=result;save(fullfile(folder,file),'-struct','data');status.Text=['Datos guardados: ' fullfile(folder,file)];
        catch err
            uialert(fig,err.message,'No se pudieron guardar los datos');
        end
    end
    function redraw(varargin)
        if isempty(result),return;end
        if strcmp(metric.Value,'Irradiación anual')
            z=result.irradiacion;unit='kWh/m²/año';name='Irradiación anual';
        else
            z=result.productividad;unit='kWh/kWp/año';name='Producción anual';
        end
        zmax=max(z,[],'all','omitnan');if ~isfinite(zmax),status.Text='No hay valores válidos para representar.';return;end
        if strcmp(scale.Value,'Porcentaje del máximo')
            if zmax<=0,status.Text='Los datos no contienen valores positivos para normalizar.';return;end
            z=100*z/zmax;unit='% del máximo';levels=0:5:100;limits=[0 100];
        else
            if zmax<=0,status.Text='Los datos no contienen valores positivos para representar.';return;end
            levels=linspace(0,zmax,21);limits=[0 zmax];
        end
        plotCartesian(z,name,unit,levels,limits);plotPolar(z,name,unit,levels,limits);
        if strcmp(metric.Value,'Irradiación anual'),raw=result.irradiacion;else,raw=result.productividad;end
        [bestRaw,k]=max(raw(:),[],'omitnan');[ii,jj]=ind2sub(size(raw),k);
        summary.Text=sprintf('%s, %.3f° N / %.3f° E\nMáximo de %s: %.1f %s · inclinación %.0f° · acimut %.0f°', ...
            result.localidad,result.latitud,result.longitud,name,bestRaw,rawUnit(),result.inclinaciones(ii),result.acimuts(jj));
    end
    function u=rawUnit()
        if strcmp(metric.Value,'Irradiación anual'),u='kWh/m²/año';else,u='kWh/kWp/año';end
    end
    function plotCartesian(z,name,unit,levels,limits)
        if isgraphics(cbCart),delete(cbCart);end
        cla(cartAx);hold(cartAx,'off');
        contourf(cartAx,result.acimuts,result.inclinaciones,z,levels,'LineStyle','none');
        clim(cartAx,limits);
        colormap(cartAx,parula(20));cbCart=colorbar(cartAx);cbCart.Label.String=unit;
        xlabel(cartAx,'Acimut PVGIS (°)');ylabel(cartAx,'Inclinación (°)');
        title(cartAx,sprintf('%s · %s · %s',result.localidad,name,unit));
        xlim(cartAx,[-170 180]);ylim(cartAx,[0 90]);grid(cartAx,'on');cartAx.Layer='top';
    end
    function plotPolar(z,name,unit,levels,limits)
        if isgraphics(cbPolar),delete(cbPolar);end
        cla(polarAx);hold(polarAx,'off');
        az=[result.acimuts result.acimuts(1)+360];el=result.inclinaciones;zclosed=[z z(:,1)];
        theta=deg2rad(az-90);[TH,R]=meshgrid(theta,el);[X,Y]=pol2cart(TH,R);
        contourf(polarAx,X,Y,zclosed,levels,'LineStyle','none');clim(polarAx,limits);hold(polarAx,'on');
        colormap(polarAx,parula(20));
        th=linspace(0,2*pi,361);
        for radius=10:10:90
            plot(polarAx,radius*cos(th),radius*sin(th),'k:','LineWidth',.55,'HandleVisibility','off');
        end
        for a=-150:30:180
            q=deg2rad(a-90);plot(polarAx,[0 90*cos(q)],[0 90*sin(q)],'k:','LineWidth',.55,'HandleVisibility','off');
            text(polarAx,99*cos(q),99*sin(q),sprintf('%d°',a), ...
                'HorizontalAlignment','center','FontSize',8,'Color',[.15 .15 .15]);
        end
        for radius=0:10:90
            text(polarAx,radius*cos(pi/4),radius*sin(pi/4),sprintf('%d°',radius), ...
                'HorizontalAlignment','center','FontSize',8,'Color',[.15 .15 .15]);
        end
        hold(polarAx,'off');axis(polarAx,'equal');xlim(polarAx,[-108 108]);ylim(polarAx,[-108 108]);
        polarAx.XTick=[];polarAx.YTick=[];polarAx.Box='off';
        cbPolar=colorbar(polarAx);cbPolar.Label.String=unit;
        title(polarAx,sprintf('%s · %s · %s',result.localidad,name,unit));
    end
end

function r=validarDatos(s,file)
required={'productividad','irradiacion'};
for k=1:numel(required)
    if ~isfield(s,required{k}),error('Falta la variable %s.',required{k});end
end
expected=[19 36];
if ~isequal(size(s.productividad),expected)||~isequal(size(s.irradiacion),expected)
    error('Las matrices deben tener tamaño 19 × 36 (inclinación 0:5:90 y acimut -170:10:180).');
end
if isfield(s,'localidad'),name=char(string(s.localidad));else,name='Localidad';end
lat=fieldOr(s,'latitud',fieldOr(s,'lat',NaN));lon=fieldOr(s,'longitud',fieldOr(s,'lon',NaN));
if (~isfinite(lat)||~isfinite(lon))
    [~,base]=fileparts(file);parts=strsplit(base,'_');
    if numel(parts)>=4,lat=str2double(parts{end-1});lon=str2double(parts{end});end
end
if ~isfinite(lat),lat=40;end;if ~isfinite(lon),lon=-5;end
incl=0:5:90;azi=-170:10:180;
if isfield(s,'inclinaciones'),incl=s.inclinaciones;end
if isfield(s,'acimuts'),azi=s.acimuts;end
maxp=fieldOr(s,'max_pro',max(s.productividad,[],'all','omitnan'));
maxh=fieldOr(s,'max_irr',max(s.irradiacion,[],'all','omitnan'));
r=struct('localidad',name,'latitud',lat,'longitud',lon,'lat',lat,'lon',lon, ...
    'productividad',s.productividad,'irradiacion',s.irradiacion,'max_pro',maxp,'max_irr',maxh, ...
    'inclinaciones',incl,'acimuts',azi);
for f={'perd_aoi','perd_esp','perd_temp'}
    if isfield(s,f{1}),r.(f{1})=s.(f{1});else,r.(f{1})=nan(expected);end
end
end

function value=fieldOr(s,name,default)
if isfield(s,name)&&isnumeric(s.(name))&&isscalar(s.(name))&&isfinite(s.(name)),value=s.(name);else,value=default;end
end
