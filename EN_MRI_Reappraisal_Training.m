function windowHandle = EN_MRI_Reappraisal_Training(folders, subject_id, session, im_order, useEyetracker)

if ~exist('useEyetracker', 'var')
    useEyetracker = true;
end

display_time = 7; % seconds for viewing / reappraising
rating_time = 4; % seconds for making an emotion rating
display_cross_cue_time = 6;
HideCursor;

results_file_name = [folders.write_folder 'SNS_MRI_R_example_S', subject_id, '_', session, '.mat'];

%% INSTRUCTIONS
instructions_4_1 = ['Exercice: \n REAPPRAISE \n\n You have as much time as you need to tell yourself a new story about the image ' ...
                    'Then you have to press the right arrow on the keyboard in order to go to the rating scale. \n\n After that you have 4 seconds for evaluating your current feeling. ' ...
                    'You can go to the left on the rating scale with the left arrow and to the right with the right one. ' ...
                    'Wenn you want to give your rating, please press the space bar. \n\n ' ...
                    'Please press the right arrow to start the exercice. '];
instructions_4_2 = ['Exercice: \n REAPPRAISE WITH TIME LIMIT \n\n Now you will exercice giving the rating within the time that you will later have during the task. You have thus 7 seconds to tell yourself a new story about the image. \n\n ' ...
                    'After that you still have 4 seconds for evaluating your current feeling. \n\n ' ...
                    'Please press the right arrow to start the exercice. '];
instructions_5 = 'Which condition did the previous block belong to?';
instructions_6 = 'The training session is over.';

%% KEYBOARD
KbName('UnifyKeyNames');
%escape_key = KbName('ESCAPE');
to_left = KbName('LeftArrow'); % green button on diamond button box
to_right = KbName('RightArrow'); % blue button on diamond button box
% define a key to confirm the rating so that we can be sure the position
% was intentional, and not just the last cursor position before the rating
% period timed out:
choice_key = KbName('space');

%% OUTPUT VARIABLES
timing = struct; %timing variable
responses = struct;
responses.responses = NaN(8,1); % responses for emotion ratings
% starting position for the rating: for sanity check - did participant move
% the cursor at all, or did they just confirm the starting position?
responses.starting_pos = NaN(8,1); 
responses.attention = '';
timing.scramble_start_times = NaN(8,1); % for pupil adaptation: record start time of the cue
timing.content_start_times = NaN(8,1);  % record start time for viewing or regulating emotion content
timing.trial_start_times = NaN(8,1); % record start time for emotion ratings
timing.reappraisal = NaN(8,1);
timing.decision_times = NaN(8,1); % time the rating was logged
timing.reaction_times = NaN(8,1); % reaction time for the rating
% to make sure that all communication with the eyetracker 
% doesn't mess up the scanner timing:
timing.instr1_start = NaN; % record start times for the instructions
timing.instr2_3_start = NaN;
timing.instr4_1_start = NaN;
timing.instr4_2_start = NaN;
timing.instr6_start = NaN;
timing.instr1_end = NaN; % record start times for the instructions
timing.instr2_3_end = NaN;
timing.instr4_1_end = NaN;
timing.instr4_2_end = NaN;
timing.instr6_end = NaN;
timing.cross_cue_start_times = NaN; % record start times for the blocks (depiction of verbal cue before block)
timing.cross_cue_decision_times = NaN;
timing.cross_cue_reaction_times = NaN;

%% FOLDERS
sam_folder = folders.sam_folder;
example_folder = folders.example_folder;

%% IMAGES
% Load the order of image pairs to be presented to the current participant
% generated with view_reappraisal_allocation.m)
im_frame = im_order.im_frame;
scale_direction = im_order.scale_direction;
cross_type = im_order.cross_type;
question_cond_cue = im_order.question_cond_cue;

% Transforme the Example images into matrices
imageMatrix = cell(8, 1); % Images to be viewed or reappraised
imageMatrixScr = cell(8, 1); % Scrambled images
for currImage = 1:8
    imageMatrix{currImage, 1} = double(imread([example_folder filesep 'Example_' num2str(currImage) '.bmp' ])); 
    imageMatrixScr{currImage, 1} = double(imread([example_folder filesep 'Example_' num2str(currImage) '_scr.bmp'] ));
end

% Transforme the SAM scale images into matrices
if strcmp(scale_direction, 'l_to_r')
    imageMatrixSAM = double(imread([sam_folder filesep 'SAM_L_to_R.jpg']));
end
if strcmp(scale_direction, 'r_to_l')
    imageMatrixSAM = double(imread([sam_folder filesep 'SAM_R_to_L.jpg']));
end

%% SCREEN
% Recognize the screen

%[windowHandle, ~] = Screen('OpenWindow', max(Screen('Screens')), [255/2 255/2 255/2]); % full screen
[windowHandle, ~] = Screen('OpenWindow', max(Screen('Screens')), [255/2 255/2 255/2], [0 0 1600 900]); % debugging mode
    
% Determine dimensions of the opened screen
[width, height] = Screen('WindowSize', windowHandle);
centerX = floor(0.5 * width);
centerY = floor(0.5 * height);

% Images position
[imageHeight, imageWidth, ~] = size(imageMatrix{1}); % assume that all the images have the same dimensions
imageRect = [centerX - imageWidth/2, centerY - imageHeight/2, centerX + imageWidth/2, centerY + imageHeight/2];
[imageHeightSAM, imageWidthSAM, ~] = size(imageMatrixSAM); % SAM images

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
        same_val_1_q = [centerX - crossSize - width/32, centerY + height/32, centerX + crossSize - width/32, centerY + height/32]; % fixation cross part '-'
        same_val_2_q = [centerX - width/32, centerY - crossSize + height/32, centerX - width/32, centerY + crossSize + height/32]; % fixation cross part '|'
        diff_val_1_q = [centerX - crossSize + width/32, centerY - crossSize + height/32, centerX + crossSize + width/32, centerY + crossSize + height/32]; % fixation cross part '\'
        diff_val_2_q = [centerX - crossSize + width/32, centerY + crossSize + height/32, centerX + crossSize + width/32, centerY - crossSize + height/32]; % fixation cross part '/'
    case 2
        diff_val_1 = [centerX - crossSize, centerY, centerX + crossSize, centerY]; % fixation cross part '-'
        diff_val_2 = [centerX, centerY - crossSize, centerX, centerY + crossSize]; % fixation cross part '|'
        same_val_1 = [centerX - crossSize, centerY - crossSize, centerX + crossSize, centerY + crossSize]; % fixation cross part '\'
        same_val_2 = [centerX - crossSize, centerY + crossSize, centerX + crossSize, centerY - crossSize]; % fixation cross part '/'
        diff_val_1_q = [centerX - crossSize + width/32, centerY + height/32, centerX + crossSize + width/32, centerY + height/32]; % fixation cross part '-'
        diff_val_2_q = [centerX + width/32, centerY - crossSize + height/32, centerX + width/32, centerY + crossSize + height/32]; % fixation cross part '|'
        same_val_1_q = [centerX - crossSize - width/32, centerY - crossSize + height/32, centerX + crossSize - width/32, centerY + crossSize + height/32]; % fixation cross part '\'
        same_val_2_q = [centerX - crossSize - width/32, centerY + crossSize + height/32, centerX + crossSize - width/32, centerY - crossSize + height/32]; % fixation cross part '/'
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
imageTexture = cell(8, 1);
imageTextureSAM = Screen('MakeTexture', windowHandle, imageMatrixSAM);
imageTextureScr = cell(8, 1); % Scrambled images
for currImage = 1:8
    imageTexture{currImage, 1} = Screen('MakeTexture', windowHandle, imageMatrix{currImage, 1});
    imageTextureScr{currImage, 1} = Screen('MakeTexture', windowHandle, imageMatrixScr{currImage, 1});
end

%% REAPPRAISAL TASK - INSTRUCTIONS
% Drawing instructions
% Drawing instructions
% check_1 = 1;
% while check_1
%     Screen('TextSize', windowHandle, txt_size_prompt);
%     Screen(windowHandle, 'FillRect', bg_color);
%     timing.instr1_start = GetSecs;
%     [~, ~, textBounds1, ~] = DrawFormattedText(windowHandle, instructions_1, 'center', 'center', txt_color, wrapat_length, [], [], 2);
%     Screen(windowHandle, 'Flip');
%     [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
%     % If any key is pressed, go out of the loop
%     if key_is_down && any(key_code(to_right))
%         timing.instr1_end = GetSecs;
%         timing.instr2_3_start = GetSecs;
%         Screen('TextSize', windowHandle, txt_size_prompt);
%         Screen(windowHandle, 'FillRect', bg_color);
%         [~, ~, textBounds, ~] = DrawFormattedText(windowHandle, instructions_2, 'center', textBounds1(2), txt_color, wrapat_length, [], [], 2);
%         Screen('DrawTexture', windowHandle, imageTextureSAM, [], [centerX - imageWidthSAM/2, textBounds(4) + 4*crossSize, centerX + imageWidthSAM/2, textBounds(4) + 4*crossSize + imageHeightSAM]);
%         DrawFormattedText(windowHandle, instructions_3, 'center', textBounds(4) + 12*crossSize + imageHeightSAM, txt_color, wrapat_length, [], [], 2);
%         Screen(windowHandle, 'Flip');
%         WaitSecs(0.5);
%         check_2 = 1;
%         while check_2
%             [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
%             % If any key is pressed, go out of the loop
%             if key_is_down && any(key_code(to_left))
%                 Screen('TextSize', windowHandle, txt_size_prompt);
%                 Screen(windowHandle, 'FillRect', bg_color);
%                 DrawFormattedText(windowHandle, instructions_1, 'center', 'center', txt_color, wrapat_length, [], [], 2);
%                 Screen(windowHandle, 'Flip');
%                 check_2 = 0;
%                 WaitSecs(0.5);
%             elseif key_is_down && any(key_code(to_right))
%                 timing.instr2_3_end = GetSecs;
%                 check_2 = 0;
%                 check_1 = 0;
%             end
%         end
%     end
% end
% WaitSecs(0.5);

%% REAPPRAISAL TASK - TRAINING - FREE TIME
Screen('TextSize', windowHandle, txt_size_prompt);
DrawFormattedText(windowHandle, instructions_4_1, 'center', 'center' , txt_color, wrapat_length, [], [], 2);
Screen('Flip', windowHandle);
check_instr = true;
timing.instr4_1_start = GetSecs;
while check_instr
    [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 

    % If any key is pressed, go out of the loop
    if key_is_down && any(key_code(to_right))
        timing.instr4_1_end = GetSecs;
        check_instr = 0;
        WaitSecs(0.5);
    end
 end
    
% CONDITION CUE
Screen('TextSize', windowHandle, txt_size_task);
DrawFormattedText(windowHandle, 'REAPPRAISE', 'center', 'center' , txt_color, wrapat_length, [], [], 2);
Screen('Flip', windowHandle);
WaitSecs(5);
% FIXATION CROSS
fct = randi(100,1); % fixation cross for training
Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(1), condition_cue_fix{im_frame(fct) + 1}(2), condition_cue_fix{im_frame(fct) + 1}(3), condition_cue_fix{im_frame(fct) + 1}(4), 2);
Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(5), condition_cue_fix{im_frame(fct) + 1}(6), condition_cue_fix{im_frame(fct) + 1}(7), condition_cue_fix{im_frame(fct) + 1}(8), 2);
Screen('Flip', windowHandle);
WaitSecs(1);
                    
for currImage = 1:4
    % SCRAMBLED IMAGE
    Screen('TextSize', windowHandle, txt_size_task);
    Screen('DrawTexture', windowHandle, imageTextureScr{currImage}, [], imageRect);
    DrawFormattedText(windowHandle, 'R', centerX - 6, centerY - 11, txt_color, wrapat_length, [], [], 2);
    Screen('Flip', windowHandle);
    timing.scramble_start_times(currImage) = GetSecs;
    WaitSecs(1); % 1 second to allow the pupil to adapt
    
    timing.content_start_times(currImage) = GetSecs;
    check = 1;
    while check
        [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
        % REGULATION / VIEW SCREEN
        Screen('TextSize', windowHandle, txt_size_task);
        Screen('DrawTexture', windowHandle, imageTexture{currImage}, [], imageRect);
        DrawFormattedText(windowHandle, 'R', centerX - 6, centerY - 11, txt_color, wrapat_length, [], [], 2);
        Screen('Flip',windowHandle);
        % If any key is pressed, go out of the loop
        if key_is_down && any(key_code(to_right))
            check = 0;
        end
    end
            
    % EMOTION RATINGS   
    Screen('TextSize', windowHandle, txt_size_task);
    Screen('DrawTexture', windowHandle, imageTextureSAM);
    DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70 , txt_color, wrapat_length, [], [], 2);
    start_rating = randi(9);
    Screen('FrameRect', windowHandle, box_color, frames{start_rating}, 5);
    Screen('Flip', windowHandle);
    
    pointerpos_curr = start_rating; 
    if strcmp(scale_direction, 'l_to_r') 
        % sad left, happy right on the 9 point SAM scale
        responses.starting_pos(currImage) = start_rating;
    end
    if strcmp(scale_direction, 'r_to_l') 
        % happy left, sad right on the 9 point SAM scale
        responses.starting_pos(currImage) = 10-start_rating;
    end  
    choice_made = false;
    flipscreen = false;
    timing.trial_start_times(currImage) = GetSecs;
    while ~choice_made && GetSecs - timing.trial_start_times(currImage) <= rating_time
    [key_is_down, ~, key_code] = KbCheck;

        if any(key_code(to_left)) && pointerpos_curr > 1 % && ensures that cursor stops at 0
            % arrow left: shift cursor with left arrow to next frame to the
            % left until space was pressed or left end of the scale was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = pointerpos_curr - 1;
            pointer_move_l = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_l}, 5);
            Screen('Flip', windowHandle);
            WaitSecs(0.2);

        elseif any(key_code(to_right)) && pointerpos_curr < 9
            % shift cursor with right arrow to next separator 
            % to the right until space is pressed or position
            % 9 was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY-70 , txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = pointerpos_curr + 1;
            pointer_move_r = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_r}, 5);
            Screen('Flip',windowHandle);
            WaitSecs(0.2);

        elseif any(key_code(to_left)) && pointerpos_curr == 1 % && ensures that cursor stops at 0                
            % arrow left: shift cursor with left arrow to next frame to the
            % left until space was pressed or left end of the scale was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = 9;
            pointer_move_l = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_l}, 5);
            Screen('Flip', windowHandle);
            WaitSecs(0.2);

        elseif any(key_code(to_right)) && pointerpos_curr == 9
            % shift cursor with right arrow to next separator 
            % to the right until space is pressed or position
            % 9 was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY-70 , txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = 1;
            pointer_move_r = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_r}, 5);
            Screen('Flip',windowHandle);
            WaitSecs(0.2);

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
    end %while loop choice
    
    if choice_made
        % display answer feedback if an answer was made:
        % selection frame changes its color to yellow
        Screen('TextSize', windowHandle, txt_size_task);
        Screen('DrawTexture', windowHandle, imageTextureSAM);
        DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70 , txt_color, wrapat_length, [], [], 2);
        Screen('FrameRect', windowHandle, confirm_color, frames{pointerpos_curr}, 5);
        Screen('Flip', windowHandle);
        WaitSecs(0.1); % display time answer feedback % this "wait" must
        % live inside this IF statement, otherwise getting too slow 
        % if the participant does not answer!
    end
            
    Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(1), condition_cue_fix{im_frame(fct) + 1}(2), condition_cue_fix{im_frame(fct) + 1}(3), condition_cue_fix{im_frame(fct) + 1}(4), 2);
    Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(5), condition_cue_fix{im_frame(fct) + 1}(6), condition_cue_fix{im_frame(fct) + 1}(7), condition_cue_fix{im_frame(fct) + 1}(8), 2);
    Screen('Flip', windowHandle);
    WaitSecs(1);
            
    timing.reappraisal(currImage) = timing.trial_start_times(currImage) - timing.content_start_times(currImage);
    save(results_file_name, 'responses', 'timing', 'im_order');
end
    
%% REAPPRAISAL TASK - TRAINING - 7 SECONDS FOR REAPPRAISING
Screen('TextSize', windowHandle, txt_size_prompt);
DrawFormattedText(windowHandle, instructions_4_2, 'center', 'center' , txt_color, wrapat_length, [], [], 2);
Screen('Flip', windowHandle);
check_instr = true;
timing.instr4_2_start = GetSecs;
while check_instr
    [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
    % If any key is pressed, go out of the loop
    if key_is_down && any(key_code(to_right))
        timing.instr4_2_end = GetSecs;
        check_instr = 0;
        WaitSecs(0.5);
    end
end
    
% CONDITION CUE
Screen('TextSize', windowHandle, txt_size_task);
DrawFormattedText(windowHandle, 'REAPPRAISE', 'center', 'center' , txt_color, wrapat_length, [], [], 2);
Screen('Flip', windowHandle);
WaitSecs(5);
% FIXATION CROSS
fct = randi(100,1); % fixation cross for training
Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(1), condition_cue_fix{im_frame(fct) + 1}(2), condition_cue_fix{im_frame(fct) + 1}(3), condition_cue_fix{im_frame(fct) + 1}(4), 2);
Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(5), condition_cue_fix{im_frame(fct) + 1}(6), condition_cue_fix{im_frame(fct) + 1}(7), condition_cue_fix{im_frame(fct) + 1}(8), 2);
Screen('Flip', windowHandle);
WaitSecs(1);
                 
for currImage = 5:8

    % SCRAMBLED IMAGE
    Screen('TextSize', windowHandle, txt_size_task);
    Screen('DrawTexture', windowHandle, imageTextureScr{currImage}, [], imageRect);
    DrawFormattedText(windowHandle, 'R', centerX - 6, centerY - 11, txt_color, wrapat_length, [], [], 2);
    Screen('Flip', windowHandle);
    timing.scramble_start_times(currImage) = GetSecs;
    WaitSecs(1); % 1 second to allow the pupil to adapt

    Screen('TextSize', windowHandle, txt_size_task);
    Screen('DrawTexture', windowHandle, imageTexture{currImage}, [], imageRect);
    DrawFormattedText(windowHandle, 'R', centerX - 6, centerY - 11, txt_color, wrapat_length, [], [], 2);
    Screen('Flip',windowHandle);
    timing.content_start_times(currImage) = GetSecs;
    WaitSecs(display_time);

    % EMOTION RATINGS   
    Screen('TextSize', windowHandle, txt_size_task);
    Screen('DrawTexture', windowHandle, imageTextureSAM);
    DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70 , txt_color, wrapat_length, [], [], 2);
    start_rating = randi(9);
    Screen('FrameRect', windowHandle, box_color, frames{start_rating}, 5);
    Screen('Flip', windowHandle);
    
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
    timing.trial_start_times(currImage) = GetSecs;
    while ~choice_made && GetSecs - timing.trial_start_times(currImage) <= rating_time

        [key_is_down, ~, key_code] = KbCheck;

        if any(key_code(to_left)) && pointerpos_curr > 1 % && ensures that cursor stops at 0
            % arrow left: shift cursor with left arrow to next frame to the
            % left until space was pressed or left end of the scale was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = pointerpos_curr - 1;
            pointer_move_l = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_l}, 5);
            Screen('Flip', windowHandle);
            WaitSecs(0.2);

        elseif any(key_code(to_right)) && pointerpos_curr < 9
            % shift cursor with right arrow to next separator 
            % to the right until space is pressed or position
            % 9 was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY-70 , txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = pointerpos_curr + 1;
            pointer_move_r = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_r}, 5);
            Screen('Flip',windowHandle);
            WaitSecs(0.2);

        elseif any(key_code(to_left)) && pointerpos_curr == 1 % && ensures that cursor stops at 0                
            % arrow left: shift cursor with left arrow to next frame to the
            % left until space was pressed or left end of the scale was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = 9;
            pointer_move_l = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_l}, 5);
            Screen('Flip', windowHandle);
            WaitSecs(0.2);

        elseif any(key_code(to_right)) && pointerpos_curr == 9
            % shift cursor with right arrow to next separator 
            % to the right until space is pressed or position
            % 9 was reached
            Screen('TextSize', windowHandle, txt_size_task);
            Screen('DrawTexture', windowHandle, imageTextureSAM);
            DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY-70 , txt_color, wrapat_length, [], [], 2);
            pointerpos_curr = 1;
            pointer_move_r = pointerpos_curr;
            Screen('FrameRect', windowHandle, box_color, frames{pointer_move_r}, 5);
            Screen('Flip',windowHandle);
            WaitSecs(0.2);

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
    end %while loop choice

    if choice_made
        % display answer feedback if an answer was made:
        % selection frame changes its color to yellow
        Screen('TextSize', windowHandle, txt_size_task);
        Screen('DrawTexture', windowHandle, imageTextureSAM);
        DrawFormattedText(windowHandle, 'CURRENT FEELING', 'center', centerY - 70 , txt_color, wrapat_length, [], [], 2);
        Screen('FrameRect', windowHandle, confirm_color, frames{pointerpos_curr}, 5);
        Screen('Flip', windowHandle);
        WaitSecs(0.1); % display time answer feedback % this "wait" must
        % live inside this IF statement, otherwise getting too slow 
        % if the participant does not answer!
    end

    Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(1), condition_cue_fix{im_frame(fct) + 1}(2), condition_cue_fix{im_frame(fct) + 1}(3), condition_cue_fix{im_frame(fct) + 1}(4), 2);
    Screen('DrawLine', windowHandle, txt_color, condition_cue_fix{im_frame(fct) + 1}(5), condition_cue_fix{im_frame(fct) + 1}(6), condition_cue_fix{im_frame(fct) + 1}(7), condition_cue_fix{im_frame(fct) + 1}(8), 2);
    Screen('Flip', windowHandle);
    WaitSecs(1);

    timing.reappraisal(currImage) = timing.trial_start_times(currImage) - timing.content_start_times(currImage);
    save(results_file_name, 'responses', 'timing', 'im_order');
end
              
%% EXAMPLE OF ATTENTION TO THE FIXED CROSS SHAPE
if ~all(isnan(question_cond_cue))
    Screen('TextSize', windowHandle, txt_size_prompt);
    Screen('FillRect', windowHandle, bg_color);
    DrawFormattedText(windowHandle, instructions_5, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
    Screen('DrawLine', windowHandle, txt_color, same_val_1_q(1), same_val_1_q(2), same_val_1_q(3), same_val_1_q(4), 2); % cross for the same valence is always
    Screen('DrawLine', windowHandle, txt_color, same_val_2_q(1), same_val_2_q(2), same_val_2_q(3), same_val_2_q(4), 2); % on the left
    Screen('DrawLine', windowHandle, txt_color, diff_val_1_q(1), diff_val_1_q(2), diff_val_1_q(3), diff_val_1_q(4), 2); % cross for differencet valences is always
    Screen('DrawLine', windowHandle, txt_color, diff_val_2_q(1), diff_val_2_q(2), diff_val_2_q(3), diff_val_2_q(4), 2); % on the right
    Screen('Flip', windowHandle);

    check = 1;
    timing.cross_cue_start_times(currImage) = GetSecs;
    while check && GetSecs - timing.cross_cue_start_times(currImage) <= display_cross_cue_time
        [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one  
        % If any key is pressed, go out of the loop
        if key_is_down && any(key_code(to_left))
            timing.cross_cue_decision_times(currImage) = GetSecs;
            timing.cross_cue_reaction_times(currImage) = timing.cross_cue_decision_times(currImage) - timing.cross_cue_start_times(currImage);        check = 0;
            if im_frame(fct) == 1
                responses.attention = 'right';
            elseif im_frame(fct) == 0
                responses.attention = 'wrong';
            end
            check = 0;
            Screen('TextSize', windowHandle, txt_size_prompt);
            Screen('FillRect', windowHandle, bg_color);
            DrawFormattedText(windowHandle, instructions_5, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
            Screen('DrawLine', windowHandle, confirm_color, same_val_1_q(1), same_val_1_q(2), same_val_1_q(3), same_val_1_q(4), 2);
            Screen('DrawLine', windowHandle, confirm_color, same_val_2_q(1), same_val_2_q(2), same_val_2_q(3), same_val_2_q(4), 2);
            Screen('DrawLine', windowHandle, txt_color, diff_val_1_q(1), diff_val_1_q(2), diff_val_1_q(3), diff_val_1_q(4), 2);
            Screen('DrawLine', windowHandle, txt_color, diff_val_2_q(1), diff_val_2_q(2), diff_val_2_q(3), diff_val_2_q(4), 2);
            Screen('Flip', windowHandle);
        elseif key_is_down && any(key_code(to_right))
            timing.cross_cue_decision_times(currImage) = GetSecs;
            timing.cross_cue_reaction_times(currImage) = timing.cross_cue_decision_times(currImage) - timing.cross_cue_start_times(currImage);
            if im_frame(fct) == 0
                responses.attention = 'right';
            elseif im_frame(fct) == 1
                responses.attention = 'wrong';
            end
            check = 0;
            Screen('TextSize', windowHandle, txt_size_prompt);
            Screen('FillRect', windowHandle, bg_color);
            DrawFormattedText(windowHandle, instructions_5, 'center', centerY - 70, txt_color, wrapat_length, [], [], 2);
            Screen('DrawLine', windowHandle, txt_color, same_val_1_q(1), same_val_1_q(2), same_val_1_q(3), same_val_1_q(4), 2);
            Screen('DrawLine', windowHandle, txt_color, same_val_2_q(1), same_val_2_q(2), same_val_2_q(3), same_val_2_q(4), 2);
            Screen('DrawLine', windowHandle, confirm_color, diff_val_1_q(1), diff_val_1_q(2), diff_val_1_q(3), diff_val_1_q(4), 2);
            Screen('DrawLine', windowHandle, confirm_color, diff_val_2_q(1), diff_val_2_q(2), diff_val_2_q(3), diff_val_2_q(4), 2);
            Screen('Flip', windowHandle);
        end
    end
    WaitSecs(0.5);

    save(results_file_name, 'responses', 'timing', 'im_order');
end

%% END OF THE TRAINING SESSION
Screen('TextSize', windowHandle, txt_size_prompt);
DrawFormattedText(windowHandle, instructions_6, 'center', 'center' , txt_color, wrapat_length, [], [], 2);
Screen('Flip', windowHandle);
check_instr = true;
timing.instr6_start = GetSecs;
while check_instr
    [key_is_down, ~, key_code] = KbCheck; % check whether a key is pressed and which one 
    % If any key is pressed, go out of the loop
    if key_is_down && any(key_code)
        timing.instr6_end = GetSecs;
        check_instr = 0;
        WaitSecs(0.5);
    end
end
Screen('CloseAll');

timing.instr1 = timing.instr1_end - timing.instr1_start;
timing.instr2_3 = timing.instr2_3_end - timing.instr2_3_start;
timing.instr4_1 = timing.instr4_1_end - timing.instr4_1_start;
timing.instr4_2 = timing.instr4_2_end - timing.instr4_2_start;
timing.instr6 = timing.instr6_end - timing.instr6_start;

save(results_file_name, 'responses', 'timing', 'im_order');
end % end of function
