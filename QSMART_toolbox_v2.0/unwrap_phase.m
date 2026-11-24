function unph=unwrap_phase(ph_corr, mask, vox, ph_unwrap_method)

imsize=size(ph_corr);

if strcmp(ph_unwrap_method,'laplacian')
    disp('--> unwrap aliasing phase using laplacian...');
    Options.voxelSize = vox;
    for i = 1:imsize(4)
        unph(:,:,:,i) = lapunwrap(ph_corr(:,:,:,i), Options);
    end
    mkdir('laplacian');
    nii = make_nii(unph, vox);
    save_nii(nii,'laplacian/unph_lap.nii');
    
elseif strcmp(ph_unwrap_method, 'bestpath')
    mkdir('bestpath');
    disp('--> unwrap aliasing phase using bestpath...');
    mask_unwrp = uint8(abs(mask)*255);
    fid = fopen('bestpath/mask_unwrp.dat','w');
    fwrite(fid,mask_unwrp,'uchar');
    fclose(fid);
    
    [pathstr, ~, ~] = fileparts(which('3DSRNCP.m'));
    setenv('pathstr',pathstr);
    setenv('nv',num2str(imsize(1)));
    setenv('np',num2str(imsize(2)));
    setenv('ns',num2str(imsize(3)));
    
    unph = zeros(imsize(1:4));
    
    for echo_num = 1:imsize(4)
        setenv('echo_num',num2str(echo_num));
        fid = fopen(['bestpath/wrapped_phase' num2str(echo_num) '.dat'],'w');
        fwrite(fid,ph_corr(:,:,:,echo_num),'float');
        fclose(fid);
        
        bash_script = ['${pathstr}/3DSRNCP bestpath/wrapped_phase${echo_num}.dat bestpath/mask_unwrp.dat ' ...
            'bestpath/unwrapped_phase${echo_num}.dat $nv $np $ns bestpath/reliability${echo_num}.dat'];
        unix(bash_script) ;
        
        fid = fopen(['bestpath/unwrapped_phase' num2str(echo_num) '.dat'],'r');
        tmp = fread(fid,'float');
        % tmp = tmp - tmp(1);
        unph(:,:,:,echo_num) = reshape(tmp - round(mean(tmp(mask==1))/(2*pi))*2*pi ,imsize(1:3)).*mask;
        fclose(fid);
    end
    
    nii = make_nii(unph,vox);
    save_nii(nii,'bestpath/unph_bestpath_before_jump_correction.nii');
    
    % remove all the temp files
    ! rm *.dat
    
    % 2pi jumps correction
    nii = load_nii('unph_diff.nii');
    unph_diff = double(nii.img);
    unph_diff = unph_diff/2;
    for echo = 2:imsize(4)
        meandiff = unph(:,:,:,echo)-unph(:,:,:,1)-double(echo-1)*unph_diff;
        meandiff = meandiff(mask==1);
        meandiff = mean(meandiff(:));
        njump = round(meandiff/(2*pi));
        disp(['    ' num2str(njump) ' 2pi jumps for TE' num2str(echo)]);
        unph(:,:,:,echo) = unph(:,:,:,echo) - njump*2*pi;
        unph(:,:,:,echo) = unph(:,:,:,echo).*mask;
    end
    nii = make_nii(unph,vox);
    save_nii(nii,'bestpath/unph_bestpath.nii');
    
end