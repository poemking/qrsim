% bare bones example of creating two completely independent
% simulators and running them in alternation

clear all
close all

% include simulator
addpath('../sim');
% include controllers
addpath('../controllers');

% first simulator
% create "real world" simulator object
qrsim_real = QRSim();

% load task parameters and do housekeeping
state_real = qrsim_real.init('TaskGotoWP');


% second simulator
% create "simulated world" simulator object
qrsim_sim = QRSim();

% load task parameters and do housekeeping
state_sim = qrsim_sim.init('TaskGotoWP');

% list of possible "actions" formulated as relative waypoints
dwp = [ 0    0    0 0;
        0    0   10 0;
        0    0  -10 0;
        0   10    0 0;
        0   10   10 0;
        0   10  -10 0;
        0  -10    0 0;
        0  -10   10 0;
        0  -10  -10 0;
       10    0    0 0;
       10    0   10 0;
       10    0  -10 0;
       10   10    0 0;
       10   10   10 0;
       10   10  -10 0;
       10  -10    0 0;
       10  -10   10 0;
       10  -10  -10 0;
      -10    0    0 0;
      -10    0   10 0;
      -10    0  -10 0;
      -10   10    0 0;
      -10   10   10 0;
      -10   10  -10 0;
      -10  -10    0 0;
      -10  -10   10 0;
      -10  -10  -10 0;];   
   
% number of times we choose a control action to solve the task
N = 50;

% number of timestep that constitute an action
M = 100; % 1 seconds

% creat PID controller object for "real world"
pid_real = WaypointPID(state_real.DT);

% creat PID controller object for simulated world
pid_sim = WaypointPID(state_sim.DT);

for i=1:N,
    
    % get the "real world" platform state
    p1_state_real = state_real.platforms{1}.getEXasX();
    
    % dumb exaustive search over possible actions
    max_reward = -Inf; best_action_idx = -1;    
    for j=1:size(dwp,1)
        
        % reset the simulation (needed to produce independent samples)
        qrsim_sim.reset();
        
        % set simulated platform to the state of the "real" platform 
        state_sim.platforms{1}.setX(p1_state_real);
        
        % the action is in term of a waypoint relative to the current
        % position, so we add the current position to it.
        tmpwp = dwp(j,:)+[p1_state_real(1:3)',0];
        
        % run the action for M timestep and compute the reward/cost
        for k=1:M
            % compute controls            
            U = pid_sim.computeU(state_sim.platforms{1}.getEX(),tmpwp);
            
            % step simulator
            qrsim_sim.step(U);            
        end
        % get reward
        tmp_reward = qrsim_sim.reward();        
        
        %fprintf('action [%f %f %f %f] :   reward %f\n',dwp(j,1),dwp(j,2),dwp(j,3),dwp(j,4),tmp_reward); 
        
        % if is the case update the max reward
        if(tmp_reward>max_reward)
            max_reward = tmp_reward;
            best_action_idx = j;
        end
        pause(0.05);
    end
    
    %fprintf('best action [%f %f %f %f] \n',dwp(best_action_idx,1),dwp(best_action_idx,2),dwp(best_action_idx,3),dwp(best_action_idx,4)); 
    
    % now that we have got the best action we can carry it out in the "real world"
    best_action_wp = dwp(best_action_idx,:)+[p1_state_real(1:3)',0];
    
    % carry out only the first part of the control action on the "real
    % world"
    for k=1:M/4
        % compute controls
        U = pid_real.computeU(state_real.platforms{1}.getEX(),best_action_wp);
        % step simulator
        qrsim_real.step(U);
    end
    
    % wait a little to allow time for rendering
    pause(0.05);
end

fprintf('Done!\n');