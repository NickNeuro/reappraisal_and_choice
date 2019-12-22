function EN_MRI_EyeTracker(subject_id, session, run)
% Master Script for ESC 1 fMRI study - Pilot: EMOTION run only!
% inputs:
% subject_id as a text string, eg '1001' for the first participant
% run = 1 / 2 / 3,
% scale_direction for left to right: 'l_to_r' / for right to left: 'r_to_l'

write_folder = 'C:\Users\nsidor\Desktop\ECON_test_OUTPUT\';
rpath = [write_folder filesep subject_id filesep 'ET'];
mkdir(rpath)

%%% initialize eyetracker
if run <= 9
    etfilename = [rpath filesep subject_id, 'r0', num2str(run)]; % file name for the saved eye tracker output
elseif run > 9
    etfilename = [rpath filesep subject_id, 'r', num2str(run)]; % file name for the saved eye tracker output
end

%status = eyelink('initialize');
%     el=eyelinkinitdefaults;

%%% Adi code
status = Eyelink('Initialize', 'PsychEyelinkDispatchCallback');
if status ~= 0
    throw(MException('EyeTracker:Initializing', ...
        'Eyetracker initializing failed!'));
end
Eyelink('command', ['add_file_preamble_text ','EL1000, visual search, wet, original name wet']);
Eyelink('command', 'calibration_type = HV5'); %%% 9 dots calibration %%%
Eyelink('command', 'saccade_velocity_threshold = 35');
Eyelink('command', 'saccade_acceleration_threshold = 9500');
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,BUTTON');
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA');
Eyelink('command', 'button_function 5 ''accept_target_fixation''');

%%% Calibration
ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
MainScreen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getScreen()+1;
MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
MonitorPositions = zeros(numel(ScreenDevices),4);
for n = 1:numel(ScreenDevices)
    Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
    MonitorPositions(n,:) = [Bounds.getLocation().getX(),-Bounds.getLocation().getY() - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
end

% Second Screen Setup MR Stimulus Computer
black = [0 0 0];
screenRect = [MonitorPositions(1,1), -1 * MonitorPositions(1,4), (MonitorPositions(1,1) + MonitorPositions(1,3)), 0];
[obj.window, ~] = Screen('OpenWindow', 2,black,screenRect);
    
%[obj.window, ~] = Screen('OpenWindow',0);
obj.eyelink = EyelinkInitDefaults(obj.window);
EyelinkDoTrackerSetup(obj.eyelink, obj.eyelink.ENTER_KEY);	% PERFORM CAMERA SETUP, CALIBRATION, force eye image on screen */
Screen('Close', obj.window);
%%% end adi code

Eyelink('openfile', etfilename);
Eyelink('startrecording');

%send message to results file
Eyelink('command', 'record_status_message ''START PARADIGM''');
Eyelink('message', 'START_RECORDING');

%%%%%%%%%%%%%%%%%%%% MAIN FUNCTION %%%%%%%%%%%%%%%%%%%%
EN_MRI_wrapper_Reappraisal_task(subject_id, session, run);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% stop eyetracker
%cd(rpath);

Eyelink('stoprecording');
Eyelink('closefile');

%%% [status =] Eyelink('ReceiveFile',['filename'], ['dest'], ['dest_is_path'])
status = Eyelink('receivefile', etfilename, rpath, 1); %%% receives edf from Eyelink computer %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Eyelink('Shutdown');

end