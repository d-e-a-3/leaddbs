function varargout=ea_ft_mesotracking_reisert(options)
% __________________________________________________________________________________
% Copyright (C) 2014 Charite University Medicine Berlin, Movement Disorders Unit
% Andreas Horn

if ischar(options) % return name of method.
    varargout{1}='Mesoscopic Fibertracking (Reisert et al. 2014)';
    varargout{2}={'SPM8','SPM12'};
    return
end

gdti_trackingparams='standard'; % select param-preset here (see below, also to create your own)
% make sure only one DTI tracker is being used.
    rmpath(genpath([options.earoot,'ext_libs',filesep,'Fibertools']));


switch gdti_trackingparams

    case 'hd_book'
        para_weight = 0.0006;
        para_other = [1
            0.001
            50
            5000000000
            0.5
            3.75
            0.2
            1];
    case 'hd_a'
        para_weight = 0.006;
        para_other = [1
            0.001
            50
            5000000000
            0.5
            3.75
            0.2
            1];
    case 'hd_a_light'
        para_weight = 0.02;
        para_other = [1
            0.001
            50
            300000000
            0.5
            3
            0.2
            1];
    case 'hd_a_verylight'
        para_weight = 0.03;
        para_other = [0.1
            0.001
            50
            300000000
            0.5
            3
            0.2
            1];
    case 'standard'
        para_weight = 0.058;
        para_other = [0.1
            0.001
            50
            300000000
            1
            3
            0.2
            1];
    case 'standard_enhanced'
        para_weight = 0.058;
        para_other = [0.1
            0.001
            50
            300000000
            1
            3
            0.2
            1.5];

end



directory=[options.root,options.patientname,filesep];
ea_prepare_dti(options)

% create c2 from anat
if ~exist([directory,'trackingmask.nii'],'file');
    if ~exist([directory,'c2',options.prefs.prenii_unnormalized],'file')
        ea_newseg(directory,options.prefs.prenii_unnormalized,0,options);
    end
    %% coreg anat to b0

    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[directory,options.prefs.b0,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[directory,'c2',options.prefs.prenii_unnormalized,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
    spm_jobman('run',{matlabbatch}); clear matlabbatch

    for c=3:5
        delete([directory,'c',num2str(c),options.prefs.prenii_unnormalized]);
    end
    movefile([directory,'rc2',options.prefs.prenii_unnormalized],[directory,'trackingmask.nii']);
end

% create c1 from anat
if ~exist([directory,'gmmask.nii'],'file');
    if ~exist([directory,'c1',options.prefs.prenii_unnormalized],'file')
        ea_newseg(directory,options.prefs.prenii_unnormalized,0,options);
    end
    %% coreg anat to b0

    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {[directory,options.prefs.b0,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {[directory,'c1',options.prefs.prenii_unnormalized,',1']};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
    spm_jobman('run',{matlabbatch}); clear matlabbatch

    for c=3:5
        delete([directory,'c',num2str(c),options.prefs.prenii_unnormalized]);
    end
    movefile([directory,'rc1',options.prefs.prenii_unnormalized],[directory,'gmmask.nii']);
end


%% mesoft part goes here


[~,dfn]=fileparts(options.prefs.dti);
try delete([directory,dfn,'_FTR.mat']); end
% addpath(genpath('/media/Data/MATLAB/release'));
% addpath(genpath('/media/Data/MATLAB/marco_reisert'));
% addpath(genpath('/media/Data/MATLAB/dti_tools'));

%ea_prepare_dti(options);




% mesoGT_tool('loadData','nii',[directory,options.prefs.dti],{[directory,options.prefs.bvec],[directory,options.prefs.bval],...
%    },[directory,'trackingmask.nii'],0.5);
mesoGT_tool('loadData','nii',[directory,options.prefs.dti],{[directory,options.prefs.bvec],[directory,options.prefs.bval],...
     },{[directory,'gmmask.nii'],[directory,'trackingmask.nii']},[128,128]);

mesoGT_tool('reset');
mesoGT_tool('start');

movefile([directory,dfn,'_FTR.mat'],[directory,options.prefs.FTR_unnormalized]);
delete(findobj('tag','fiberGT_main'))
%
%
%% export .trk copy for trackvis visualization

dnii=nifti([directory,options.prefs.b0]);
niisize=size(dnii.dat); % get dimensions of reference template.
specs.origin=[0,0,0];
specs.dim=niisize;
specs.affine=dnii.mat;

[~,ftrfname]=fileparts(options.prefs.FTR_unnormalized);
ea_ftr2trk(ftrfname,directory,specs,options); % export unnormalized ftr to .trk
disp('Done.');






