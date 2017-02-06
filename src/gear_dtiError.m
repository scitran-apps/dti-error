function gear_dtiError(input_directory, output_directory, error_type, ncoords, wm_prob)
%
% gear_dtiError(input_directory, output_directory, error_type, ncoords, wm_prob)
%
% Wrapper function for compliation of dtiError, which will allow a run of
% this code from within a Flywheel Gear.
%
%
% EXAMPLE USAGE:
%     input_directory = fullfile(pwd, 'local', 'dtiInit_27-Jan-2017_18-51-24');
%     ncoords = 150;
%     output_directory = fullfile(pwd, 'local');
%     error_type = 'all'
%     wm_prob='true'
%     gear_dtiError(input_directory, output_directory, error_type, ncoords, wm_prob)
%
% EXAMPLE COMPILATION:
%     mcc -m gear_dtiError.m -I ~/Code/vistasoft
%

disp('Alive...');

%% Handle inputs

% Generate path to aligned (motion-corrected) diffusion nifti file.
diffusion_nifti = mrvFindFile('*aligned*.nii.gz', input_directory);
if numel(diffusion_nifti) > 1
    warning('More than 1 diffusion nifti file was found. Using first file found to run:  \n%s', diffusion_nifti{1});
end
diffusion_nifti = diffusion_nifti{1};

% White matter probability
if strcmpi(wm_prob, 'true')
    wm_prob = true;
    wmProb = mrvFindFile('wmProb.nii.gz', input_directory);
else
    wm_prob = false;
end

% Error type
if strcmpi(error_type, 'all')
    eType = {'adc', 'dsig'};
else
    eType{1} = error_type;
end

% Ncoords
if ischar(ncoords)
    ncoords = str2double(ncoords);
end

%% Run the error calculation

for ii = 1:numel(eType)
    if wm_prob
        [err, dwi, coords, measured, predicted] = dtiError(diffusion_nifti, 'wmProb', wmProb{1}, 'eType', eType{ii}, 'ncoords', ncoords);
    else
        [err, dwi, coords, measured, predicted] = dtiError(diffusion_nifti, 'eType',  eType{ii}, 'ncoords', ncoords);
    end
    
    % PLOTS
    
    % Histogram
    mrvNewGraphWin;
    hist(err,50); xlabel(['\Delta ', upper(eType{ii})]); ylabel('Voxel Count')
    fprintf('%s: DWI image quality (1/std(err)) = %.2f \n', upper(eType{ii}), 1/std(err));
    title(sprintf('%s: DWI image quality (1/std(err)) = %.2f \n', upper(eType{ii}), 1/std(err)));
    saveas(gcf, fullfile(output_directory, [eType{ii}, '_', num2str(ncoords), '_err.png']));
    
    % Scatter with id/line
    plot(measured, predicted,'o')
    xlabel([upper(eType{ii}), ' Measured'])
    ylabel([upper(eType{ii}), ' Predicted'])
    title([upper(eType{ii}), ' Measured/Predicted']);
    identityLine(gca); axis equal
    saveas(gcf, fullfile(output_directory,  [eType{ii}, '_', num2str(ncoords), '_measured_predicted.png']));
    
    
    switch lower(eType{ii})
        case 'adc'
            % Plot surface and points
            adc = dwiGet(dwi,'adc data image',coords);
            Q = dwiQ(dwi,coords);
            dwiPlot(dwi,'adc',adc(:,5),squeeze(Q(:,:,5)));
            
            % Write out gif of surface vs measured
            gif_file = fullfile(output_directory, [ eType{ii}, '_', num2str(ncoords), '_surface.gif' ] );
            
            % Turn of the axes and loop through the views
            lightH = camlight('right');
            axis('off');
            axis('image');axis('vis3d');
            for ff = 1:180
                % rotate the camera
                camorbit(2, 0);
                
                % Rotate the light with the camera
                lightH = camlight(lightH,'right');
                
                % Caputure the frame
                mov(ff) = getframe(gcf);
                
                % Convert the movie frame to an image
                im = frame2im(mov(ff));
                [imind, cm] = rgb2ind(im, 256);
                
                % Write out the image to gif
                if ff == 1;
                    imwrite(imind, cm, gif_file, 'gif', 'Loopcount',inf, 'delaytime',0);
                else
                    imwrite(imind, cm, gif_file, 'gif', 'WriteMode', 'append', 'delaytime',0);
                end
            end
        case 'dsig'
            % Not implemented
            continue
    end
end

% If running via MCR exit
if isdeployed
    exit(0)
end

return