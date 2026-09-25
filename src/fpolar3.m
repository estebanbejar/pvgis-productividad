%% Script: Gráfico polar con etiquetas diagonales (Elevación de 0º a 90º)

% Nombre del archivo CSV (ajusta la ruta si es necesario)
% fileName = 'Salamanca_40.9688_-5.6639.csv';

function fpolar3(data,etiqueta,localidad,latitud,longitud)


% Cerrar la matriz: repetir la primera columna al final para un dominio angular completo
data_closed = [data, data(:,1)];

%% Definir vectores para elevación y azimut
% Elevación: de 0º a 90º
elevacion = linspace(0, 90, size(data,1));

% Azimut en grados: de -170º a 180º (36 puntos)
azimut_deg = linspace(-170, 180, size(data,2));
% Para cerrar el dominio, se añade el ángulo que cierra la figura: -170 + 360 = 190º
azimut_deg_closed = [azimut_deg, 190];

% Rotar el gráfico 90º en sentido horario: restar 90º a cada ángulo
azimut_rot_deg = azimut_deg_closed - 90;
theta = deg2rad(azimut_rot_deg);

%% Crear la malla en coordenadas polares y convertir a cartesianas
[TH, R] = meshgrid(theta, elevacion);
[X, Y] = pol2cart(TH, R);

%% Graficar el contorno
figure;
%contourf(X, Y, data_closed, 'LineStyle', 'none');  % Dibujar el contorno rellenado
%colormap(parula);                                    % Usar 'parula'
%caxis([min(data_closed(:)) max(data_closed(:))]);    % Ajustar la escala de colores
vMin = min(data_closed(:), [], 'omitnan'); % Cálculo del rango
vMax = max(data_closed(:), [], 'omitnan');
niveles = linspace(vMin, vMax, 21);   % pasos del 5% del rango
contourf(X, Y, data_closed, niveles, 'LineStyle', 'none');
colormap(parula);
caxis([vMin vMax]);
cb = colorbar;
cb.Label.String = etiqueta;
axis equal;                                          % Proporciones iguales

% Ocultar los ejes cartesianos
ax = gca;
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';

% Título con metadatos
title({['Localidad: ' localidad], ['Latitud: ', num2str(latitud), '°, Longitud: ', num2str(longitud), '°']});

hold on;
%% Dibujar la malla polar
% Dibujar círculos concéntricos (elevación) de 0º a 90º con saltos de 10º
r_ticks = 0:10:90;
theta_full = linspace(0, 2*pi, 360);
for r_val = r_ticks
    [x_circ, y_circ] = pol2cart(theta_full, r_val*ones(size(theta_full)));
    plot(x_circ, y_circ, 'k:', 'HandleVisibility', 'on');
end
% Dibujar líneas radiales cada 30° (en los ángulos sin rotar)
for th = deg2rad(0:30:330)
    [x_rad, y_rad] = pol2cart(th, [0, 90]);
    plot(x_rad, y_rad, 'k:', 'HandleVisibility', 'on');
end

%% Añadir etiquetas de elevación en posición diagonal (a 45º)
angle_label = deg2rad(45);  % Posición diagonal
for r_val = r_ticks
    [x_text, y_text] = pol2cart(angle_label, r_val);
    text(x_text, y_text, num2str(r_val), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'Color', 'k', 'FontSize', 10);
end

%% Añadir etiquetas para el azimut
azimuth_ticks = -150:15:180;
for k = 1:length(azimuth_ticks)
    tick = azimuth_ticks(k);
    % Calcular el ángulo rotado: tick - 90
    tick_rot = deg2rad(tick - 90);
    % Ubicar la etiqueta en la periferia: radio = 90 + offset (por ejemplo, 5 unidades)
    r_label = 90 + 5;
    [x_text, y_text] = pol2cart(tick_rot, r_label);
    text(x_text, y_text, num2str(tick), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'Color', 'k', 'FontSize', 10);
end
hold off;

% Ajustar límites para ver la malla polar completa
xlim([-110 110]);
ylim([-110 110]);

end