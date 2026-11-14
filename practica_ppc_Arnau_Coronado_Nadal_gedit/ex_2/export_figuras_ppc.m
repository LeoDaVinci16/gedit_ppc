% =====================================================================
% Script per exportar gràfiques de Simulink a PNG (300 dpi)
% Fitxer: export_figuras_ppc.m
% =====================================================================

% 1. Crear la carpeta 'figuras' si no existeix
if ~exist('figuras', 'dir')
    mkdir('figuras');
end

% 2. Nom de la imatge a generar (modifica segons l'exercici)
nombre_figura = 'ejercicio2_pi_tuning'; 

% 3. Comprovar que la simulació s'ha executat
if ~exist('out', 'var')
    error('❌ No es troba la variable ''out''. Executa primer la simulació a Simulink (Ctrl+T).');
end

% 4. Obtenir el temps des de out.tout
t = out.tout;

% 5. Extreure la potència mesurada
if isprop(out, 'Pppc_meas') || isfield(out, 'Pppc_meas')
    % Si has usat el bloc To Workspace anomenat Pppc_meas
    dades = out.Pppc_meas;
    if isa(dades, 'timeseries')
        P_meas = dades.Data;
    else
        P_meas = dades;
    end
elseif isprop(out, 'simout') || isfield(out, 'simout')
    % Si has usat el Scope Logging anomenat simout
    dades = out.simout;
    if isa(dades, 'Simulink.SimulationData.Dataset')
        P_meas = dades.get(1).Values.Data;
    elseif isa(dades, 'timeseries')
        P_meas = dades.Data(:,1);
    else
        P_meas = dades(:,1);
    end
else
    error('❌ No s''han trobat dades de potència a ''out''. Revisa la configuració del bloc To Workspace.');
end

% 6. Reconstrucció de la consigna teòrica P_ref
P_ref = ones(size(t)) * P_tso_ini;
P_ref(t >= step_time) = P_tso_fin;

% Si P_meas té múltiples columnes, agafem només la columna de la potència mesurada
if size(P_meas, 2) > 1
    P_meas = P_meas(:, 1); % Canvia '1' per la columna de la mesura si és una altra
end

% 7. Creació de la figura amb format professional
fig = figure('Name', nombre_figura, 'Units', 'centimeters', 'Position', [2 2 16 10]);

plot(t, P_ref, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Consigna TSO (P_{TSO})');
hold on;
plot(t, P_meas, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Potència Mesurada PCC (P_{pcc})');
hold off;

grid on; grid minor;
xlabel('Temps [s]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Potència Activa [kW]', 'FontSize', 11, 'FontWeight', 'bold');
if exist('Kp','var') && exist('Ki','var')
    title(sprintf('Resposta del PPC (Kp = %g, Ki = %g)', Kp, Ki), 'FontSize', 12);
else
    title('Resposta del PPC al PCC', 'FontSize', 12);
end
legend('Location', 'best', 'FontSize', 10);
xlim([0 max(t)]);

% 8. Desar la imatge en alta resolució a la carpeta figuras/
ruta_sortida = fullfile('figuras', [nombre_figura, '.png']);
exportgraphics(fig, ruta_sortida, 'Resolution', 300);

fprintf('✅ Imatge guardada correctament a: %s\n', ruta_sortida);