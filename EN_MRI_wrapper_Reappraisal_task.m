function EN_MRI_wrapper_Reappraisal_task(subject_id, session, run)
    
    %% ARGUMENTS
    general_folder = 'C:\Users\nsidor\Desktop\Nick\';
    folders = struct;
    folders.subject_folder = dir(fullfile(general_folder, '**', 'MRI', '**', ['subject_', subject_id])); folders.subject_folder = folders.subject_folder.folder;
    folders.image_folder = dir(fullfile(general_folder, '**', 'IAPS')); folders.image_folder = folders.image_folder.folder;
    folders.scr_folder = dir(fullfile(general_folder, '**', 'IAPS_scrambled')); folders.scr_folder = folders.scr_folder.folder;
    folders.sam_folder = dir(fullfile(general_folder, '**', 'SAM_scale')); folders.sam_folder = folders.sam_folder.folder;
    folders.example_folder = dir(fullfile(general_folder, '**', 'Examples')); folders.example_folder = folders.example_folder.folder;
    folders.write_folder = 'C:\Users\nsidor\Desktop\ECON_test_OUTPUT\';
    im_order = load([folders.subject_folder filesep 'SNS_MRI_R_set_S', subject_id, '_', session, '.mat']); 
    useEyetracker = 0;
    
    %% INSTRUCTIONS
    nbImages = numel(im_order.images_order);
    [responses, timing] = EN_MRI_Reappraisal_task(subject_id, folders, im_order, session, useEyetracker, nbImages, run);
    save([folders.write_folder 'SNS_MRI_R_task_S', subject_id, '_', session, '_', num2str(run), '_backup.mat'], 'responses', 'timing');
    
end