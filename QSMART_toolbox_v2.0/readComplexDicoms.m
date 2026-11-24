function [mag_all,ph_all,dicom_info]= readComplexDicoms(path_mag,path_pha)

% read in DICOMs of both uncombined magnitude and raw unfiltered phase images
path_mag = cd(cd(path_mag));  
mag_list = dir([path_mag '/**/*.dcm']);%%% a struct with the list of dicoms for mag
mag_list = mag_list(~strncmpi('.', {mag_list.name}, 1)); %%%strncmpi(s1,s2,n)= compares the first n characters of 2 strings- it also returns '.' and '..' which refer to current and parent directory which are omitted in this line
path_pha = cd(cd(path_pha));
ph_list = dir([path_pha '/**/*.dcm']);
ph_list = ph_list(~strncmpi('.', {ph_list.name}, 1));
% number of slices (mag and ph should be the same)
nSL = length(ph_list); 

% get the sequence parameters
dicom_info = dicominfo([ph_list(end).folder,filesep,ph_list(end).name]);%%%filesep is the file separator for the current directory ('/' ex.) %% gets the info of the last dicom
NumberOfEchoes = dicom_info.EchoNumber; 

for i = 1:nSL/NumberOfEchoes:nSL % read in TEs
    dicom_info = dicominfo([ph_list(i).folder,filesep,ph_list(i).name]);
    TE(dicom_info.EchoNumber) = dicom_info.EchoTime*1e-3; %% store TE s in msec
end
dicom_info.echo_times=TE;
dicom_info.resolution = [dicom_info.PixelSpacing(1), dicom_info.PixelSpacing(2), dicom_info.SliceThickness];%%voxel dimensions

% angles (z projections of the image x y z coordinates) 
Xz = dicom_info.ImageOrientationPatient(3);
Yz = dicom_info.ImageOrientationPatient(6);
Zxyz = cross(dicom_info.ImageOrientationPatient(1:3),dicom_info.ImageOrientationPatient(4:6));
Zz = Zxyz(3);
dicom_info.z_prjs = [Xz, Yz, Zz];

% read in measurements
mag = zeros(dicom_info.Rows,dicom_info.Columns,nSL,'single'); %%matrix with image dimensions %% image dimension is the mozaic dimension (private_0051_100b.*[6 6] if 32 coils)
ph = zeros(dicom_info.Rows,dicom_info.Columns,nSL,'single');

for i = 1:nSL
    %i
    fprintf('---Reading Image no. %d ---.\n',i)
    mag(:,:,i) = single(dicomread([mag_list(i).folder,filesep,mag_list(i).name]));
    ph(:,:,i) = single(dicomread([ph_list(i).folder,filesep,ph_list(i).name]));
end  %%reads dicoms and stores them in 'single' type matrix


% crop mosaic into individual images
if isnumeric(dicom_info.Private_0051_100b)
    AcqMatrix = regexp(native2unicode(dicom_info.Private_0051_100b','ISO_IR 6'),'(\d)*(\d)','match');
else
    AcqMatrix = regexp(dicom_info.Private_0051_100b,'(\d)*(\d)','match');
end
if strcmpi(dicom_info.InPlanePhaseEncodingDirection,'COL') % A/P
% phase encoding along column
    wRow = round(str2num(AcqMatrix{1})/dicom_info.PercentSampling*100);
    wCol = str2num(AcqMatrix{2});
else % L/R
    wCol = round(str2num(AcqMatrix{1})/dicom_info.PercentSampling*100);
    wRow = str2num(AcqMatrix{2});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tic;
% works for square 32 channels (faster)
%seperate the channels and reshape into COLS, ROWS, SLICES, ECHOES, CHANS
mag = mat2cell(mag,[wRow wRow wRow wRow wRow wRow], [wCol wCol wCol wCol wCol wCol], nSL);
mag_all = cat(4,mag{1,1}, mag{1,2}, mag{1,3}, mag{1,4}, mag{1,5}, mag{1,6}, mag{2,1}, mag{2,2}, mag{2,3}, mag{2,4}, mag{2,5}, mag{2,6}, mag{3,1}, mag{3,2}, mag{3,3}, mag{3,4}, mag{3,5}, mag{3,6}, mag{4,1}, mag{4,2}, mag{4,3}, mag{4,4}, mag{4,5}, mag{4,6}, mag{5,1}, mag{5,2}, mag{5,3}, mag{5,4}, mag{5,5}, mag{5,6}, mag{6,1}, mag{6,2});
clear mag
mag_all = reshape(mag_all, wRow, wCol, nSL/NumberOfEchoes, NumberOfEchoes, 32);
mag_all = permute(mag_all,[2 1 3 4 5]); %%%seperates image of each coil 5*6+2=32

ph = mat2cell(ph,[wRow wRow wRow wRow wRow wRow], [wCol wCol wCol wCol wCol wCol], nSL);
ph_all = cat(4,ph{1,1}, ph{1,2}, ph{1,3}, ph{1,4}, ph{1,5}, ph{1,6}, ph{2,1}, ph{2,2}, ph{2,3}, ph{2,4}, ph{2,5}, ph{2,6}, ph{3,1}, ph{3,2}, ph{3,3}, ph{3,4}, ph{3,5}, ph{3,6}, ph{4,1}, ph{4,2}, ph{4,3}, ph{4,4}, ph{4,5}, ph{4,6}, ph{5,1}, ph{5,2}, ph{5,3}, ph{5,4}, ph{5,5}, ph{5,6}, ph{6,1}, ph{6,2});
clear ph
ph_all = reshape(ph_all, wRow, wCol, nSL/NumberOfEchoes, NumberOfEchoes, 32);
ph_all = permute(ph_all,[2 1 3 4 5]);
ph_all = 2*pi.*(ph_all - single(dicom_info.SmallestImagePixelValue))/(single(dicom_info.LargestImagePixelValue - dicom_info.SmallestImagePixelValue)) - pi; %%%scales the phase to -pi:pi range

