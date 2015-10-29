%% demo_example_gp_training

%% Description
% This demo presents how to train, i.e., identify, GP model, which
% describes the nonlinear dynamic system.

%% See Also
% demo_example, demo_example_gp_data, demo_example_gp_simulation,
% demo_example_norm, gp, gpx, gp_initial, trainGParx, trainGPoe 
 
clear all;
close all;

% load data from file
load example_data 

% Build training data (delayed outputs y first) 
input = [xtrain utrain]; 
target = [ytrain]; 

% Define covariance function: the squared exponential covariance function with
% ARD
cov = @covSEard; 

% Define covariance function: the Gaussian likelihood function.
lik = @likGauss;

% Define mean function: the zero mean function.
mean = @meanZero;

% Define inference method: the exact Inference
inf= @infExact;

%% Setting initial hyperparameters
% For hyperparameters a structure array is used. The structure array has to be of the
% following shape:
% hyp = 
%      cov: [] - covariance function parameters
%      lik: [] - likelyhood function parameters
%      mean: [] -  mean function parameters
% 
% To get the number of hyperparameters you may
% use: eval_func(cov),  eval_func(cov) or eval_func(mean).
%

D = size(input,2); % Input space dimension
hyp0.cov  = -ones(D+1,1); 

% Define the likelihood hyperparameter. In our case this parameter is the noise
% parameter.
hyp0.lik=log(0.1);
 
hyp0.mean = []; 

%% gp_initial
% We can also use the function gp_initial to find initial hperparameters.
% This function returns the best set of n random sets of hyperparameter values. 
% As score it uses a log marginal likelihood. The number of parameters
% is adjusted to the current covariance, likelihood and mean function.% 

% Set between which bounds the best set of hyperparameters will be estimated.
bounds=[-7,8];

% Find initial hyperparameters:
hyp0_lin = gp_initial(bounds, inf, mean, @covLINard, lik, input, target);

% For further use we will train another GP model with linear covariance
% function(@covLINard).


%% Training 
% Identification of GP model
[hyp, flogtheta, i] = trainGParx(hyp0, inf, mean, cov, lik, input, target);

% Training using Differential Evolution minimization algorithm with default value of iterations:
[hyp_lin, flogtheta_lin, i] = trainGParx(hyp0_lin, inf, mean, @covLINard, lik, input, target, @minimizeDE);

% Training using Output Error algorithm
[hyp_oe, flogtheta, i] = trainGPoe(hyp0, inf, mean, cov, lik, input, target, @simulGPmc, 1);

%% Validation (Regression)
% validation on identification data 
[ytest S2test] = gp(hyp, inf, mean, cov, lik, input, target, input);

% plot
t = [0:length(input)-1]';
f1=figure('Name', 'Validation on Identification Data');
plotgp(f1,t,target, ytest, sqrt(S2test));

% validation on validation dataset (regression) 
[ytest2 S2test2] = gp(hyp, inf, mean, cov, lik, input, target, [xvalid uvalid]);

%polot
t = [0:length(uvalid)-1]';
f2=figure('Name', 'Validation on Validation Data (Regression)');
plotgp(f2,t,yvalid, ytest2, sqrt(S2test2));

% save trained GP model to file 
save example_trained hyp hyp_lin inf mean cov lik input target



return; 



