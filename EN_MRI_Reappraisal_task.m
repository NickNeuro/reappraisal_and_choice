function [responses, timing] = EN_MRI_Reappraisal_task(subject_id, folders, im_order, session, useEyetracker, nbImages, run)
% fMRI emotion reappraisal task that presents IAPS pictures

% inputs: 
% subject_id as a string, eg '1001'
% scale_direction: 'l_to_r' for left to right or 'r_to_l' for right to left
% (negative -> positive directionality)
% useEyetracker: logical (1 = eyetracking is recorded, 0 = not recorded)

% cue is presented before block, on top of the image just a small
% reminder to not divert gaze away from center of the image

%%%% QUALITY CHECK %%%%
if ~exist('useEyetracker', 'var')
    useEyetracker = true;
end

TR = 2.293; % TR (repetition time) for acquisition of 1 volume
display_time = 7; % seconds for viewing / reappraising
rating_time = 4; % seconds for making an emotion rating
display_cross_cue_time = 6;
%HideCursor;

% Output file
results_file_name = [folders.write_folder 'SNS_MRI_R_task_S', subject_id, '_', session, '_', num2str(run) '.mat'];

% Check to prevent overwriting previous data
a = exist([results_file_name '.mat'], 'file');
if a
    writeover = input('Filename already exists, do you want to overwrite? 1 = yes, 0 = no ');
else
    writeover = 2; % no messages necessary
end

switch writeover
    case 0
        subject_id = input('Enter proper subject ID as text string: ');
    case 1
        disp('Results file will be overwritten')
end
% clear a, writeover

%%%% PREPARATIONS %%%%
%% INSTRUCTIONS
instructions_1 = ['In this task you will see a row of IMAGES. ' ...
    'After each block there is always a short pause. \n\n ' ...
    'Before the block is always displayed a cue indicating whether you need to "VIEW" the images without telling a new story or ' ... 
    ' to "REAPPRAISE" in order weaken to the evoked feeling. ' ...
    'A small reminder "V" (view) or "R" (reappraise) will appear on the image. \n\n' ...
    'To follow the instructions, please press the right (blue) button. '];
instructions_2 = 'After that please rate your current feeling using the following scale: ';
instructions_3 = ['You can go to the left of the scale with the left (green) button ' ...
    'and to the right with the right (blue) one. To confrm your rating please press the top (red) button. \n\n ' ...
    'Wenn you are ready, please press the right (blue) button to start the task. '];
instructions_question = 'Which condition does the previous block belong to?';


%% KEYBOARD
KbName('UnifyKeyNames');
%escape_key = KbName('ESCAPE');
to_left = KbName('g'); % green button on diamond button box
to_right = KbName('b'); % blue button on diamond button box
% define a key to confirm the rating so that we can be sure the position
% was intentional, and not just the last cursor position before the rating
% period timed out:
choice_made = {'r'}; % red is the top button on the diamond button box
trigger_name = {'t'}; % signal the scanner sends for the trigger
choice_key = KbName(choice_made);
trigger_key = KbName(trigger_name);
escape_key = KbName('ESCAPE');
condition_cue = {'VIEW', 'REAPPRAISE'}; % reappraise or view condition
condition_cue_short = {'V', 'R'}; % short reminder for reappraise or view condition

%% OUTPUT VARIABLES
timing = struct; %timing variable
responses = struct;
responses.responses = NaN(nbImages,1); % responses for emotion ratings
% starting position for the rating: for sanity check - did participant move
% the cursor at all, or did they just confirm the starting position?
responses.starting_pos = NaN(nbImages,1); 
responses.cross_cue = NaN(nbImages,1);
responses.answer_side = NaN(nbImages,1);
responses.attention = strings(nbImages,1);
responses.start_success = NaN(nbImages,1);
responses.reapp_success = NaN(nbImages,1);
timing.scramble_start_times = NaN(nbImages,1); % for pupil adaptation: record start time of the cue
timing.content_start_times = NaN(nbImages,1);  % record start time for viewing or regulating emotion content
timing.trial_start_times = NaN(nbImages,1); % record start time for emotion ratings
timing.decision_times = NaN(nbImages,1); % time the rating was logged
timing.reaction_times = NaN(nbImages,1); % reaction time for the rating
% to make sure that all communication with the eyetracker 
% doesn't mess up the scanner timing:
timing.loopTimer = NaN(nbImages,1); 
timing.blank_start_times = NaN(nbImages,1); % record start times for ITI
timing.break_start_time = NaN(nbImages,1); % record start times for the breaks
timing.break_end_time = NaN(nbImages,1); % record end times for the breaks
timing.cross_cue_start_times = NaN(nbImages,1); % record start times for the blocks (depiction of verbal cue before block)
timing.cross_cue_decision_times = NaN(nbImages, 1);
timing.cross_cue_reaction_times = NaN(nbImages, 1);
timing.success_start_times = NaN(nbImages,1); % record start times for the blocks (depiction of verbal cue before block)
timing.success_decision_times = NaN(nbImages, 1);
timing.success_reaction_times = NaN(nbImages, 1);

%% TRIALS FOR A GIVEN RUN
trials = 1:18; % there are 18 images per run
for i = 1:18
    trials(i) = trials(i) + (run-1)*18;
end

%% FOLDERS
image_folder = folders.image_folder;
scr_folder = folders.scr_folder;
sam_folder = folders.sam_folder;

%% IMAGES
% Load the order of image pairs to be presented to the current participant
% generated with view_reappraisal_allocation.m)
image_order = im_order.images_order;
runs = im_order.runs;
jitter = im_order.jitter;
im_frame = im_order.im_frame;
scale_direction = im_order.scale_direction;
v_r_cond = im_order.v_r_cond;
question_cond_cue = im_order.question_cond_cue;
cross_type = im_order.cross_type;
cross_type_side = im_order.cross_type_side; cross_type_counter = 1;

% Transforme the IAPS images into matrices
imageMatrix = cell(nbImages, 1); % Images to be viewed or reappraised
imageMatrixScr = cell(nbImages, 1); % Scrambled images
for currImage = 1:nbImages
    imageMatrix{currImage, 1} = double(imread([image_folder filesep num2str(image_order(currImage, 1)) '.jpg' ])); 
    imageMatrixScr{currImage, 1} = double(imread([scr_folder filesep num2str(image_order(currImage, 1)) '.jpg' ])); % first image from the pair
end
% Transforme the SAM scale images into matrices
imageMatrixSAM = cell(nbImages, 1);
if strcmp(scale_direction, 'l_to_r')
    for currImage = 1:nbImages
        imageMatrixSAM{currImage, 1} = double(imread([sam_folder filesep 'SAM_L_to_R.jpg']));
    end
end
if strcmp(scale_direction, 'r_to_l')
    for currImage = 1:nbImages
        imageMatrixSAM{currImage, 1} = double(imread([sam_folder filesep 'SAM_R_to_L.jpg']));
    end
end

%% SCREEN
% Recognize the screen
[windowHandle, ~] = Screen('OpenWindow', max(Screen('Screens')), [0.5 0.5 0.5], [0 0 800 800]); % debugging mode
% ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
% MainScreen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getScreen()+1;
% MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
% MonitorPositions = zeros(numel(ScreenDevices),4);
% for n = 1:numel(ScreenDevices)
%     Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
%     MonitorPositions(n,:) = [Bounds.getLocation().getX(),-Bounds.getLocation().getY() - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
% end
% 
% % Second Screen Setup MR Stimulus Computer
% black = [0 0 0];
% screenRect = [MonitorPositions(1,1), -1 * MonitorPositions(1,4), (MonitorPositions(1,1) + MonitorPositions(1,3)), 0];
% [windowHandle, rect] = Screen('OpenWindow', 2,black, screenRect);
% Determine dimensions of the opened screen
[width, height] = Screen('WindowSize', windowHandle);
centerX = floor(0.5 * width);
centerY = floor(0.5 * height);

% Images position
[imageHeight, imageWidth, ~] = size(imageMatrix{1,1}); % assume that all the images have the same dimensions
imageRect = [centerX - imageWidth/2, centerY - imageHeight/2, centerX + imageWidth/2, centerY + imageHeight/2];
[imageHeightSAM, imageWidthSAM, ~] = size(imageMatrixSAM{1}); % SAM images

% Colors and text
txt_color = [200 200 200]; % off white
box_color = [255 255 0]; % yellow
confirm_color = [0 255 255]; % turquoisevie
bg_color = GrayIndex(windowHandle, 0.5); % 0.5 = middle gray, 0 = black, 1 = white
crossSize = height/72;
switch cross_type
    case 1
        same_val_1 = [centerX - crossSize, centerY, centerX + crossSize, centerY]; % fixation cross part '-'
        same_val_2 = [centerX, centerY - crossSize, centerX, centerY + crossSize]; % fixation cross part '|'
        diff_val_1 = [centerX - crossSize, centerY - crossSize, centerX + crossSize, centerY + crossSize]; % fixation cross part '\'
        diff_val_2 = [centerX - crossSize, centerY + crossSize, centerX + crossSize, centerY - crossSize]; % fixation cross part '/'
        same_val_1_q_left = [centerX - crossSize - width/32, centerY + height/32, centerX + crossSize - width/32, centerY + height/32]; % fixation cross part '-'
        same_val_2_q_left = [centerX - width/32, centerY - crossSize + height/32, centerX - width/32, centerY + crossSize + height/32]; % fixation cross part '|'
        diff_val_1_q_right = [centerX - crossSize + width/32, centerY - crossSize + height/32, centerX + crossSize + width/32, centerY + crossSize + height/32]; % fixation cross part '\'
        diff_val_2_q_right = [centerX - crossSize + width/32, centerY + crossSize + height/32, centerX + crossSize + width/32, centerY - crossSize + height/32]; % fixation cross part '/'
        same_val_1_q_right = [centerX - crossSize + width/32, centerY + height/32, centerX + crossSize + width/32, centerY + height/32]; % fixation cross part '-'
        same_val_2_q_right = [centerX + width/32, centerY - crossSize + height/32, centerX + width/32, centerY + crossSize + height/32]; % fixation cross part '|'
        diff_val_1_q_left = [centerX - crossSize - width/32, centerY - crossSize + height/32, centerX + crossSize - width/32, centerY + crossSize + height/32]; % fixation cross part '\'
        diff_val_2_q_left = [centerX - crossSize - width/32, centerY + crossSize + height/32, centerX + crossSize - width/32, centerY - crossSize + height/32]; % fixation cross part '/'
    case 2
        diff_val_1 = [centerX - crossSize, centerY, centerX + crossSize, centerY]; % fixation cross part '-'
        diff_val_2 = [centerX, centerY - crossSize, centerX, centerY + crossSize]; % fixation cross part '|'
        same_val_1 = [centerX - crossSize, centerY - crossSize, centerX + crossSize, centerY + crossSize]; % fixation cross part '\'
        same_val_2 = [centerX - crossSize, centerY + crossSize, centerX + crossSize, centerY - crossSize]; % fixation cross part '/'
        diff_val_1_q_right = [centerX - crossSize + width/32, centerY + height/32, centerX + crossSize + width/32, centerY + height/32]; % fixation cross part '-'
        diff_val_2_q_right = [centerX + width/32, centerY - crossSize + height/32, centerX + width/32, centerY + crossSize + height/32]; % fixation cross part '|'
        same_val_1_q_left = [centerX - crossSize - width/32, centerY - crossSize + height/32, centerX + crossSize - width/32, centerY + crossSize + height/32]; % fixation cross part '\'
        same_val_2_q_left = [centerX - crossSize - width/32, centerY + crossSize + height/32, centerX + crossSize - width/32, centerY - crossSize + height/32]; % fixation cross part '/'
        diff_val_1_q_left = [centerX - crossSize - width/32, centerY + height/32, centerX + crossSize - width/32, centerY + height/32]; % fixation cross part '-'
        diff_val_2_q_left = [centerX - width/32, centerY - crossSize + height/32, centerX - width/32, centerY + crossSize + height/32]; % fixation cross part '|'
        same_val_1_q_right = [centerX - crossSize + width/32, centerY - crossSize + height/32, centerX + crossSize + width/32, centerY + crossSize + height/32]; % fixation cross part '\'
        same_val_2_q_right = [centerX - crossSize + width/32, centerY + crossSize + height/32, centerX + crossSize + width/32, centerY - crossSize + height/32]; % fixation cross part '/'
end
condition_cue_fix = {[diff_val_1, diff_val_2], [same_val_1, same_val_2]};
wrapat_length = round(height/18);
Screen('TextFont', windowHandle,'Arial');
txt_size_prompt = round(height/36);
txt_size_task = round(height/36);

% Selection frames on the SAM
frame_width = imageWidthSAM/9;
frame1 = [centerX - frame_width*4.5, centerY - imageHeightSAM/2, centerX - frame_width*3.5, centerY + imageHeightSAM/2];
frame2 = [centerX - frame_width*3.5, centerY - imageHeightSAM/2, centerX - frame_width*2.5, centerY + imageHeightSAM/2];
frame3 = [centerX - frame_width*2.5, centerY - imageHeightSAM/2, centerX - frame_width*1.5, centerY + imageHeightSAM/2];
frame4 = [centerX - frame_width*1.5, centerY - imageHeightSAM/2, centerX - frame_width*0.5, centerY + imageHeightSAM/2];
frame5 = [centerX - frame_width*0.5, centerY - imageHeightSAM/2, centerX + frame_width*0.5, centerY + imageHeightSAM/2];
frame6 = [centerX + frame_width*0.5, centerY - imageHeightSAM/2, centerX + frame_width*1.5, centerY + imageHeightSAM/2];
frame7 = [centerX + frame_width*1.5, centerY - imageHeightSAM/2, centerX + frame_width*2.5, centerY + imageHeightSAM/2];
frame8 = [centerX + frame_width*2.5, centerY - imageHeightSAM/2, centerX + frame_width*3.5, centerY + imageHeightSAM/2];
frame9 = [centerX + frame_width*3.5, centerY - imageHeightSAM/2, centerX + frame_width*4.5, centerY + imageHeightSAM/2];
frames = {frame1,frame2,frame3,frame4,frame5,frame6,frame7,frame8,frame9};

%% CREATE TEXTURES
% Transforme pictures into textures
imageTexture = cell(nbImages, 1);
imageTextureScr = cell(nbImages, 1);
imageTextureSAM = cell(nbImages, 1);
for currImage = 1:nbImages
    imageTexture{currImage, 1} = Screen('MakeTexture', windowHandle, imageMatrix{currImage, 1});
    imageTextureScr{currImage, 1} = Screen('MakeTexture', windowHandle, imageMatrixScr{currImage, 1});
    imageTextureSAM{currImage, 1} = Screen('MakeTexture', windowHandle, imageMatrixSAM{currImage, 1});
end

%% INSTRUCTIONS
if run == 1
    check_1 = 1;
    while check_1
        Screen('TextSize', windowHandle, txt_size_prompt);
        Screen(windowHandle, 'FillRect', bg_color);
        [~, ~, textBounds1, ~] = DrawFormattedText(windowHandle, instructions_1, 'center', 'center', txt_color, wrapat_length, [], [], 2);
        Screen(windowHandle, 'Flip');
        [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
        % If any key is pressed, go out of the loop
        if key_is_down && any(key_code(to_right))
            Screen('TextSize', windowHandle, txt_size_prompt);
            Screen(windowHandle, 'FillRect', bg_color);
            [~, ~, textBounds, ~] = DrawFormattedText(windowHandle, instructions_2, 'center', textBounds1(2), txt_color, wrapat_length, [], [], 2);
            Screen('DrawTexture', windowHandle, imageTextureSAM{1,1}, [], [centerX - imageWidthSAM/2, textBounds(4) + 4*crossSize, centerX + imageWidthSAM/2, textBounds(4) + 4*crossSize + imageHeightSAM]);
            DrawFormattedText(windowHandle, instructions_3, 'center', textBounds(4) + 12*crossSize + imageHeightSAM, txt_color, wrapat_length, [], [], 2);
            Screen(windowHandle, 'Flip');
            WaitSecs(0.5);
            check_2 = 1;
            while check_2
                [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
                % If any key is pressed, go out of the loop
                if key_is_down && any(key_code(to_left))
                    Screen('TextSize', windowHandle, txt_size_prompt);
                    Screen(windowHandle, 'FillRect', bg_color);
                    DrawFormattedText(windowHandle, instructions_1, 'center', 'center', txt_color, wrapat_length, [], [], 2);
                    Screen(windowHandle, 'Flip');
                    check_2 = 0;
                    WaitSecs(0.5);
                elseif key_is_down && any(key_code)
                    check_2 = 0;
                    check_1 = 0;
                end
            end
        end
    end
    WaitSecs(0.5);
end

%% TASK - VIEWING AND REAPPRAISAL

try
    % Waiting for scanning 
    Screen('TextSize', windowHandle, txt_size_prompt);
    Screen(windowHandle, 'FillRect', bg_color);
    DrawFormattedText(windowHandle, 'Wait for scanner', 'center', 'center', txt_color);
    Screen(windowHandle, 'Flip');
    FlushEvents;
    
    % Wait for scanner trigger (expects a "t" input!)
    waiting_for_scanner = 1;
    while waiting_for_scanner
        [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
        % If any key is pressed
        if key_is_down && any(key_code(trigger_key))
            waiting_for_scanner = 0;
            timing.start_time = GetSecs; % start of the scanner timing!
            if useEyetracker
                %send message to EyeLink recording file
                Eyelink('message', 'ExpStart');
                WaitSecs(0.01); % wait 10 milliseconds to send the message
            end 
        end
    end
    
    % Preparing for scanning
    Screen('TextSize', windowHandle, txt_size_task);
    Screen('FillRect', windowHandle, bg_color);
    % Draw the fixation cross
    Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(1) + 1}(1), condition_cue_fix{im_frame(1) + 1}(2), condition_cue_fix{im_frame(1) + 1}(3), condition_cue_fix{im_frame(1) + 1}(4), 2);
    Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(1) + 1}(5), condition_cue_fix{im_frame(1) + 1}(6), condition_cue_fix{im_frame(1) + 1}(7), condition_cue_fix{im_frame(1) + 1}(8), 2);
    Screen('Flip', windowHandle);
    a = tic();    
    % initial fixation period of 2 * TR, 
    % subtract the 0.01 seconds wait time for the eyetracker message
    % (we always used the eyetracker while scanning)
    WaitSecs(2*TR - 0.01); 
    disp(['After 2*TR: ' num2str(toc(a))]);
    for currImage = trials % Main draw loop
        
        % first show cue for this block
        if currImage == 1 || (currImage ~=1 && ~isequal(runs(currImage), runs(currImage - 1)))
            Screen('TextSize', windowHandle, txt_size_task);
            DrawFormattedText(windowHandle, condition_cue{v_r_cond(currImage)}, 'center', 'center' , txt_color, wrapat_length, [], [], 2);
            Screen('Flip', windowHandle);
            timing.cross_cue_start_times(currImage) = GetSecs;
            WaitSecs(5);
            disp(['After condition cue: ' num2str(currImage) ' ' num2str(toc(a))]);
            % Fixation cross after pause
            Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(1), condition_cue_fix{im_frame(currImage) + 1}(2), condition_cue_fix{im_frame(currImage) + 1}(3), condition_cue_fix{im_frame(currImage) + 1}(4), 2);
            Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(5), condition_cue_fix{im_frame(currImage) + 1}(6), condition_cue_fix{im_frame(currImage) + 1}(7), condition_cue_fix{im_frame(currImage) + 1}(8), 2);
            Screen('Flip', windowHandle); 
            WaitSecs(1);
            disp(['After first fixation cross: ' num2str(currImage) ' ' num2str(toc(a))]);
        end
        
        % DISPLAY SCRAMBLED IMAGE for adapting pupil response
        Screen('TextSize', windowHandle, txt_size_task);
        Screen('DrawTexture', windowHandle, imageTextureScr{currImage, 1}, [], imageRect);
        % with condition cue on top of the picture
        DrawFormattedText(windowHandle, condition_cue_short{v_r_cond(currImage)}, centerX - 6, centerY - 11, txt_color, wrapat_length, [], [], 2);
        Screen('Flip', windowHandle);
        loopTimer = tic();
        timing.scramble_start_times(currImage) = GetSecs();
        WaitSecs(1); % 1 second to allow the pupil to adapt
        disp(['After scrambled image: '  num2str(currImage) ' ' num2str(toc(a))]);
        % REGULATION / VIEW SCREEN
        Screen('TextSize', windowHandle, txt_size_task);
        Screen('DrawTexture', windowHandle, imageTexture{currImage, 1}, [], imageRect);
        % with condition cue on top of the picture
        DrawFormattedText(windowHandle, condition_cue_short{v_r_cond(currImage)}, centerX - 6, centerY - 11, txt_color, wrapat_length, [], [], 2);
        Screen('Flip',windowHandle);
        timing.content_start_times(currImage) = GetSecs;
        WaitSecs(display_time); % 7 seconds content display
        disp(['After content image: '  num2str(currImage) ' ' num2str(toc(a))]);
        % EMOTION RATINGS   
        Screen('TextSize', windowHandle, txt_size_task);
        Screen('DrawTexture', windowHandle, imageTextureSAM{currImage, 1});
        DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70 , txt_color, wrapat_length, [], [], 2);
        
        % on top of the scale: draw yellow square that randomly pops up in one spot
        start_rating = randi(9);
        Screen('FrameRect', windowHandle, box_color, frames{start_rating}, 5);
        Screen('Flip', windowHandle);
        timing.trial_start_times(currImage) = GetSecs;
        
        % move the selection frame left or right to answer, confirm the
        % answer with the space bar
        
        % needs to be outside while loop! otherwise cursor does not move
        pointerpos_curr = start_rating; 
        if strcmp(scale_direction, 'l_to_r') 
            % sad left, happy right on the 9 point SAM scale
            responses.starting_pos(currImage) = start_rating;
        end
        if strcmp(scale_direction, 'r_to_l') 
            % happy left, sad right on the 9 point SAM scale
            responses.starting_pos(currImage) = 10-start_rating;
        end  
        % read out answer
        choice_made = false;
        flipscreen = false;
        while ~choice_made
            
            [key_is_down, ~, key_code] = KbCheck;
            
            if any(key_code(to_left)) && pointerpos_curr > 1 % && ensures that cursor stops at 0
                
                % arrow left: shift cursor with left arrow to next frame to the
                % left until space was pressed or left end of the scale was reached
                Screen('TextSize', windowHandle, txt_size_task);
                Screen('DrawTexture', windowHandle, imageTextureSAM{currImage, 1});
                DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                pointerpos_curr = pointerpos_curr - 1;
                pointer_move_l = pointerpos_curr;
                Screen('FrameRect', windowHandle, box_color, frames{pointer_move_l}, 5);
                Screen('Flip', windowHandle);
                WaitSecs(0.1);
                
            elseif any(key_code(to_right)) && pointerpos_curr < 9
                % shift cursor with right arrow to next separator 
                % to the right until space is pressed or position
                % 9 was reached
                Screen('TextSize', windowHandle, txt_size_task);
                Screen('DrawTexture', windowHandle, imageTextureSAM{currImage, 1});
                DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY-70 , txt_color, wrapat_length, [], [], 2);
                pointerpos_curr = pointerpos_curr + 1;
                pointer_move_r = pointerpos_curr;
                Screen('FrameRect', windowHandle, box_color, frames{pointer_move_r}, 5);
                Screen('Flip',windowHandle);
                WaitSecs(0.1);
                
            elseif any(key_code(to_left)) && pointerpos_curr == 1 % && ensures that cursor stops at 0                
                % arrow left: shift cursor with left arrow to next frame to the
                % left until space was pressed or left end of the scale was reached
                Screen('TextSize', windowHandle, txt_size_task);
                Screen('DrawTexture', windowHandle, imageTextureSAM{currImage, 1});
                DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                pointerpos_curr = 9;
                pointer_move_l = pointerpos_curr;
                Screen('FrameRect', windowHandle, box_color, frames{pointer_move_l}, 5);
                Screen('Flip', windowHandle);
                WaitSecs(0.1);
                
            elseif any(key_code(to_right)) && pointerpos_curr == 9
                % shift cursor with right arrow to next separator 
                % to the right until space is pressed or position
                % 9 was reached
                Screen('TextSize', windowHandle, txt_size_task);
                Screen('DrawTexture', windowHandle, imageTextureSAM{currImage, 1});
                DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY-70 , txt_color, wrapat_length, [], [], 2);
                pointerpos_curr = 1;
                pointer_move_r = pointerpos_curr;
                Screen('FrameRect', windowHandle, box_color, frames{pointer_move_r}, 5);
                Screen('Flip',windowHandle);
                WaitSecs(0.1);
                
            elseif key_is_down && any(key_code(choice_key)) && length(find(key_code))<2
                % confirm answer by pressing the red button on the button box
                if strcmp(scale_direction, 'l_to_r') 
                    % sad left, happy right on the 9 point SAM scale
                    responses.responses(currImage) = pointerpos_curr;
                end
                if strcmp(scale_direction, 'r_to_l') 
                    % happy left, sad right on the 9 point SAM scale
                    responses.responses(currImage) = 10-pointerpos_curr;
                end
                timing.decision_times(currImage) = GetSecs;
                timing.reaction_times(currImage) = timing.decision_times(currImage) - timing.trial_start_times(currImage);
                choice_made = true;
                break;
            end
            
            if key_is_down && key_code(escape_key)
                save(results_file_name, 'responses', 'timing', 'im_order');
                break;
            end
            
            if (GetSecs - timing.trial_start_times(currImage)) >= rating_time % 4 seconds rating time
                disp('no rating made')
                break;
            end
        end %while loop choice
        
        if ~isnan(responses.responses(currImage))
            % display answer feedback if an answer was made:
            % selection frame changes its color to yellow
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM{currImage, 1});
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70 , txt_color, wrapat_length, [], [], 2);
            Screen('FrameRect', windowHandle, confirm_color, frames{pointerpos_curr}, 5);
            Screen('Flip', windowHandle);
            WaitSecs(0.1); % display time answer feedback % this "wait" must
            % live inside this IF statement, otherwise getting too slow 
            % if the participant does not answer!
        end
        disp(['After rating: ' num2str(currImage) ' ' num2str(toc(a))]);
        % If there is no question about the cross shape
        if isnan(question_cond_cue(currImage))
            % fixation cross of upcoming image - jittered ITI
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('FillRect', windowHandle, bg_color);
            if currImage ~= trials(end)
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage + 1) + 1}(1), condition_cue_fix{im_frame(currImage + 1) + 1}(2), condition_cue_fix{im_frame(currImage + 1) + 1}(3), condition_cue_fix{im_frame(currImage + 1) + 1}(4), 2);
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage + 1) + 1}(5), condition_cue_fix{im_frame(currImage + 1) + 1}(6), condition_cue_fix{im_frame(currImage + 1) + 1}(7), condition_cue_fix{im_frame(currImage + 1) + 1}(8), 2);
                Screen('Flip', windowHandle);
                timing.blank_start_times(currImage) = GetSecs;
                WaitSecs(abs(rating_time - timing.reaction_times(currImage) - 0.1));
                WaitSecs(jitter(currImage));
                timing.loopTimer(currImage) = toc(loopTimer);
                disp(['After jitter: ' num2str(currImage) ' ' num2str(toc(a))]);
            else
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(1), condition_cue_fix{im_frame(currImage) + 1}(2), condition_cue_fix{im_frame(currImage) + 1}(3), condition_cue_fix{im_frame(currImage) + 1}(4), 2);
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(5), condition_cue_fix{im_frame(currImage) + 1}(6), condition_cue_fix{im_frame(currImage) + 1}(7), condition_cue_fix{im_frame(currImage) + 1}(8), 2);
                Screen('Flip', windowHandle);
                timing.blank_start_times(currImage) = GetSecs;
                WaitSecs(abs(rating_time - timing.reaction_times(currImage) - 0.1));
                WaitSecs(jitter(currImage));
                disp(['After jitter: ' num2str(currImage) ' ' num2str(toc(a))]);
                timing.loopTimer(currImage) = toc(loopTimer);
                WaitSecs(10*TR);
                disp(['After 10*TR: ' num2str(currImage) ' ' num2str(toc(a))]);
            end
            
            save(results_file_name, 'responses',  'timing', 'im_order'); % save here to update results on every loop
            
        end
        
        % CHECK OF ATTENTION TO THE FIXED CROSS SHAPE
        % If there is a question about the cross shape
        if ~isnan(question_cond_cue(currImage))
            % fixation cross of the current image - jittered ITI 
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('FillRect', windowHandle, bg_color);
            Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(1), condition_cue_fix{im_frame(currImage) + 1}(2), condition_cue_fix{im_frame(currImage) + 1}(3), condition_cue_fix{im_frame(currImage) + 1}(4), 2);
            Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(5), condition_cue_fix{im_frame(currImage) + 1}(6), condition_cue_fix{im_frame(currImage) + 1}(7), condition_cue_fix{im_frame(currImage) + 1}(8), 2);
            Screen('Flip', windowHandle);
            timing.blank_start_times(currImage) = GetSecs;
            WaitSecs(abs(rating_time - timing.reaction_times(currImage)));
            WaitSecs(jitter(currImage));
            timing.loopTimer(currImage) = toc(loopTimer);
            disp(['After jitter: ' num2str(currImage) ' ' num2str(toc(a))]);
            save(results_file_name, 'responses',  'timing', 'im_order'); % save here to update results on every loop
            
            % Question about the shape of the cross
            switch cross_type_side(cross_type_counter)
                case 1
                    cross_type_counter = cross_type_counter + 1;
                    Screen('TextSize', windowHandle, txt_size_prompt);
                    Screen('FillRect', windowHandle, bg_color);
                    DrawFormattedText(windowHandle, instructions_question, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                    Screen('DrawLine', windowHandle, txt_color, same_val_1_q_right(1), same_val_1_q_right(2), same_val_1_q_right(3), same_val_1_q_right(4), 2); % cross for the same valence on the right
                    Screen('DrawLine', windowHandle, txt_color, same_val_2_q_right(1), same_val_2_q_right(2), same_val_2_q_right(3), same_val_2_q_right(4), 2);
                    Screen('DrawLine', windowHandle, txt_color, diff_val_1_q_left(1), diff_val_1_q_left(2), diff_val_1_q_left(3), diff_val_1_q_left(4), 2); % cross for differencet valences on the left
                    Screen('DrawLine', windowHandle, txt_color, diff_val_2_q_left(1), diff_val_2_q_left(2), diff_val_2_q_left(3), diff_val_2_q_left(4), 2); 
                    Screen('Flip', windowHandle);

                    check = 1;
                    timing.cross_cue_start_times(currImage) = GetSecs;
                    while check && (GetSecs - timing.cross_cue_start_times(currImage)) <= display_cross_cue_time
                    [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one  
                      % If any key is pressed, go out of the loop
                      if key_is_down && any(key_code(to_left))
                          timing.cross_cue_decision_times(currImage) = GetSecs;
                          timing.cross_cue_reaction_times(currImage) = timing.cross_cue_decision_times(currImage) - timing.cross_cue_start_times(currImage);
                          responses.cross_cue(currImage) = 0; % selected the different valences
                          responses.answer_side(currImage) = 1;
                          if question_cond_cue(currImage) == 0
                            responses.attention(currImage) = 'right';
                          else
                            responses.attention(currImage) = 'wrong';
                          end
                          check = 0;
                          Screen('TextSize', windowHandle, txt_size_prompt);
                          Screen('FillRect', windowHandle, bg_color);
                          DrawFormattedText(windowHandle, instructions_question, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                          Screen('DrawLine', windowHandle, txt_color, same_val_1_q_right(1), same_val_1_q_right(2), same_val_1_q_right(3), same_val_1_q_right(4), 2);
                          Screen('DrawLine', windowHandle, txt_color, same_val_2_q_right(1), same_val_2_q_right(2), same_val_2_q_right(3), same_val_2_q_right(4), 2);
                          Screen('DrawLine', windowHandle, confirm_color, diff_val_1_q_left(1), diff_val_1_q_left(2), diff_val_1_q_left(3), diff_val_1_q_left(4), 2);
                          Screen('DrawLine', windowHandle, confirm_color, diff_val_2_q_left(1), diff_val_2_q_left(2), diff_val_2_q_left(3), diff_val_2_q_left(4), 2);
                          Screen('Flip', windowHandle);
                          WaitSecs(0.1);
                      elseif key_is_down && any(key_code(to_right))
                          timing.cross_cue_decision_times(currImage) = GetSecs;
                          timing.cross_cue_reaction_times(currImage) = timing.cross_cue_decision_times(currImage) - timing.cross_cue_start_times(currImage);
                          responses.cross_cue(currImage) = 1; % selected the same valence
                          responses.answer_side(currImage) = 2;
                          if question_cond_cue(currImage) == 0
                              
                            responses.attention(currImage) = 'wrong';
                          else
                            responses.attention(currImage) = 'right';
                          end
                          check = 0;
                          Screen('TextSize', windowHandle, txt_size_prompt);
                          Screen('FillRect', windowHandle, bg_color);
                          DrawFormattedText(windowHandle, instructions_question, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                          Screen('DrawLine', windowHandle, confirm_color, same_val_1_q_right(1), same_val_1_q_right(2), same_val_1_q_right(3), same_val_1_q_right(4), 2); % cross for the same valence on the right
                          Screen('DrawLine', windowHandle, confirm_color, same_val_2_q_right(1), same_val_2_q_right(2), same_val_2_q_right(3), same_val_2_q_right(4), 2);
                          Screen('DrawLine', windowHandle, txt_color, diff_val_1_q_left(1), diff_val_1_q_left(2), diff_val_1_q_left(3), diff_val_1_q_left(4), 2); % cross for differencet valences on the left
                          Screen('DrawLine', windowHandle, txt_color, diff_val_2_q_left(1), diff_val_2_q_left(2), diff_val_2_q_left(3), diff_val_2_q_left(4), 2);                          
                          Screen('Flip', windowHandle);
                          WaitSecs(0.1);
                      end
                    end
                case 2
                    cross_type_counter = cross_type_counter + 1;
                    Screen('TextSize', windowHandle, txt_size_prompt);
                    Screen('FillRect', windowHandle, bg_color);
                    DrawFormattedText(windowHandle, instructions_question, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                    Screen('DrawLine', windowHandle, txt_color, same_val_1_q_left(1), same_val_1_q_left(2), same_val_1_q_left(3), same_val_1_q_left(4), 2); % cross for the same valence on the left
                    Screen('DrawLine', windowHandle, txt_color, same_val_2_q_left(1), same_val_2_q_left(2), same_val_2_q_left(3), same_val_2_q_left(4), 2);
                    Screen('DrawLine', windowHandle, txt_color, diff_val_1_q_right(1), diff_val_1_q_right(2), diff_val_1_q_right(3), diff_val_1_q_right(4), 2); % cross for differencet valences on the right
                    Screen('DrawLine', windowHandle, txt_color, diff_val_2_q_right(1), diff_val_2_q_right(2), diff_val_2_q_right(3), diff_val_2_q_right(4), 2); 
                    Screen('Flip', windowHandle);

                    check = 1;
                    timing.cross_cue_start_times(currImage) = GetSecs;
                    while check && (GetSecs - timing.cross_cue_start_times(currImage)) <= display_cross_cue_time
                    [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one  
                      % If any key is pressed, go out of the loop
                      if key_is_down && any(key_code(to_left))
                          timing.cross_cue_decision_times(currImage) = GetSecs;
                          timing.cross_cue_reaction_times(currImage) = timing.cross_cue_decision_times(currImage) - timing.cross_cue_start_times(currImage);
                          responses.cross_cue(currImage) = 1;
                          responses.answer_side(currImage) = 1;
                          if question_cond_cue(currImage) == 0
                            responses.attention(currImage) = 'wrong';
                          else
                            responses.attention(currImage) = 'right';
                          end
                          check = 0;
                          Screen('TextSize', windowHandle, txt_size_prompt);
                          Screen('FillRect', windowHandle, bg_color);
                          DrawFormattedText(windowHandle, instructions_question, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                          Screen('DrawLine', windowHandle, confirm_color, same_val_1_q_left(1), same_val_1_q_left(2), same_val_1_q_left(3), same_val_1_q_left(4), 2);
                          Screen('DrawLine', windowHandle, confirm_color, same_val_2_q_left(1), same_val_2_q_left(2), same_val_2_q_left(3), same_val_2_q_left(4), 2);
                          Screen('DrawLine', windowHandle, txt_color, diff_val_1_q_right(1), diff_val_1_q_right(2), diff_val_1_q_right(3), diff_val_1_q_right(4), 2);
                          Screen('DrawLine', windowHandle, txt_color, diff_val_2_q_right(1), diff_val_2_q_right(2), diff_val_2_q_right(3), diff_val_2_q_right(4), 2);
                          Screen('Flip', windowHandle);
                          WaitSecs(0.1);
                      elseif key_is_down && any(key_code(to_right))
                          timing.cross_cue_decision_times(currImage) = GetSecs;
                          timing.cross_cue_reaction_times(currImage) = timing.cross_cue_decision_times(currImage) - timing.cross_cue_start_times(currImage);
                          responses.answer_side(currImage) = 2;
                          responses.cross_cue(currImage) = 0;
                          if question_cond_cue(currImage) == 0
                            responses.attention(currImage) = 'right';
                          else
                            responses.attention(currImage) = 'wrong';
                          end
                          check = 0;
                          Screen('TextSize', windowHandle, txt_size_prompt);
                          Screen('FillRect', windowHandle, bg_color);
                          DrawFormattedText(windowHandle, instructions_question, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
                          Screen('DrawLine', windowHandle, txt_color, same_val_1_q_left(1), same_val_1_q_left(2), same_val_1_q_left(3), same_val_1_q_left(4), 2);
                          Screen('DrawLine', windowHandle, txt_color, same_val_2_q_left(1), same_val_2_q_left(2), same_val_2_q_left(3), same_val_2_q_left(4), 2);
                          Screen('DrawLine', windowHandle, confirm_color, diff_val_1_q_right(1), diff_val_1_q_right(2), diff_val_1_q_right(3), diff_val_1_q_right(4), 2);
                          Screen('DrawLine', windowHandle, confirm_color, diff_val_2_q_right(1), diff_val_2_q_right(2), diff_val_2_q_right(3), diff_val_2_q_right(4), 2);
                          Screen('Flip', windowHandle);
                          WaitSecs(0.1);
                      end
                    end
            end
            disp(['After cross shape question: ' num2str(currImage) ' ' num2str(toc(a))]);
            
            if currImage ~= trials(end)
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(1), condition_cue_fix{im_frame(currImage) + 1}(2), condition_cue_fix{im_frame(currImage) + 1}(3), condition_cue_fix{im_frame(currImage) + 1}(4), 2);
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(5), condition_cue_fix{im_frame(currImage) + 1}(6), condition_cue_fix{im_frame(currImage) + 1}(7), condition_cue_fix{im_frame(currImage) + 1}(8), 2);
                Screen('Flip', windowHandle);
                WaitSecs(abs(display_cross_cue_time - timing.cross_cue_reaction_times(currImage) - 0.1));
                WaitSecs(1);
                disp(['Jitter after cross shape question: ' num2str(currImage) ' ' num2str(toc(a))]);
            else
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(1), condition_cue_fix{im_frame(currImage) + 1}(2), condition_cue_fix{im_frame(currImage) + 1}(3), condition_cue_fix{im_frame(currImage) + 1}(4), 2);
                Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(currImage) + 1}(5), condition_cue_fix{im_frame(currImage) + 1}(6), condition_cue_fix{im_frame(currImage) + 1}(7), condition_cue_fix{im_frame(currImage) + 1}(8), 2);
                Screen('Flip', windowHandle);
                WaitSecs(abs(display_cross_cue_time - timing.cross_cue_reaction_times(currImage) - 0.1));
                WaitSecs(1);
                disp(['Jitter after cross shape question: ' num2str(currImage) ' ' num2str(toc(a))]);
                WaitSecs(10*TR);
                disp(['After 10*TR: ' num2str(currImage) ' ' num2str(toc(a))]);
            end
        end   
        
        if useEyetracker
            % send message to EyeLink recording file
            Eyelink('message', sprintf('trial: %d', currImage));
            Eyelink('command', sprintf('record_status_message ''End trial %d''', currImage));
        end
    end % end of main draw loop
    
    if useEyetracker
        %send message to EyeLink recording file
        Eyelink('message', 'RunEnd');
        Eyelink('command', 'record_status_message ''RunEnd''');
    end
    
    disp(['Before save: ' num2str(currImage) ' ' num2str(toc(a))]);
    save(results_file_name, 'responses',  'timing', 'im_order'); 
    disp(['After save: ' num2str(currImage) ' ' num2str(toc(a))]);
catch
    
    psychrethrow(psychlasterror);
    
end %end of try-catch
disp(['After run: ' num2str(currImage) ' ' num2str(toc(a))]);

save(results_file_name, 'responses', 'timing', 'im_order');
Screen('CloseAll');
end