clc; clear all; close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                   %
% This script is a demo of QSMART pipeline developed                %
% at the Melbourne Brain Centre Imaging Unit.                       %
%                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath('./QSMART_toolbox_v1.0'));

%%% Defining data paths and string IDs%%%
  
datapath_mag='';
datapath_pha='';
out_path='./QSMART_out/';
% Path to utility code
qsm_params.mexEig3volume=which('eig3volume.c');

%%% Setting QSM Parameters %%%

% Scanner/Imaging Parameters
qsm_params.species='human';               % 'human' or 'rodent'
qsm_params.field=7;                       % Tesla
qsm_params.gyro=2.675e8;                  % Proton gyromagnetic ratio  
qsm_params.datatype='DICOM_Siemens';      % options: DICOM_Siemens, BRUKER, 'AAR_Siemens', 'ZIP_Siemens'
qsm_params.phase_encoding='unipolar';     % 'unipolar' or 'bipolar'

% Coil combination
qsm_params.coilcombmethod='smooth3';  % options: s(1) smooth3, (2) poly3, (3) poly3_nlcg

% Phase unwrapping 
qsm_params.ph_unwrap_method='laplacian';    %options: 'laplacian','bestpath'

% Threshold parameters
qsm_params.mag_threshold=100;
qsm_params.sph_radius1=2;
qsm_params.sph_radius_vasculature = 8;
qsm_params.adaptive_threshold=0;

% Frangi filter parameters
qsm_params.frangi_scaleRange=[0.5 6];
qsm_params.frangi_scaleRatio=0.5;
qsm_params.frangi_C=500;

% Multiecho fit parameters
qsm_params.fit_threshold=40;

% Background field removal

% Spatial dependent filtering parameters
qsm_params.sdf_sp_radius=8;
qsm_params.s1.sdf_sigma1=10;
qsm_params.s1.sdf_sigma2=0;
qsm_params.s2.sdf_sigma1=8;
qsm_params.s2.sdf_sigma2=2;
qsm_params.sdffilterLowerLim=0.6;
qsm_params.sdffilterCurvConstant=500;

% RESHARP Parameters
qsm_params.resharp.smv_rad = 1;
qsm_params.resharp.tik_reg = 5e-4;
qsm_params.resharp.cgs_num = 500;

% iLSQR Parameters
qsm_params.cgs_num = 500;
qsm_params.inv_num = 500;
qsm_params.smv_rad = .1;

% Adaptive threshold parameters
qsm_params.seg_thres_percentile = 100;
qsm_params.smth_thres_percentile = 100;                % iLSQR-smoothing high-susc segmentation

% Data output
qsm_params.save_raw_data=0;

% QSMART 
QSMART(datapath_mag,datapath_pha,qsm_params,out_path);    
    

