% Stochastic ADMM proposed by Ouyang Hua in http://jmlr.org/proceedings/papers/v28/ouyang13.pdf
function outputs = STOC_ADMM(samples, labels, opts)
time_min_run = opts.min_t;
F = opts.F; mu = opts.mu; beta = opts.beta; gamma = opts.gamma; eta = 0.01;
max_it = opts.max_it; checki = opts.checki;
if isfield(opts,'scaling')
    scaling = opts.scaling;
else
    scaling = 1;
end
eta = eta*scaling;

% Initialization
t = cputime; time_solving = 0; xs = []; times = []; iters = []; Num_i  = 0;
[d,N] = size(samples); rnd_pm = randperm(N);
x = zeros(d,1); y = zeros(d-1,1); zeta = zeros(d-1,1); xbar = zeros(d,1);
eta_inv = 1/eta; betaFT = beta*F';
if d < 500
    InvFFT = inv(eta_inv*eye(d) + beta*(F'*F));
else
    InvFFT = inv(eta_inv*speye(d) + beta*(F'*F));
end

done = false; k = 0;
while ~done
    % Randomly choose a sample
    idx = rnd_pm(mod(k,N)+1);
    sample = samples(:,idx);
    label  = labels(idx);
    
    % Stochastic ADMM
    t_exp = exp(-label*sample'*x);
    if isnan(t_exp) || isinf(t_exp)
        g = -label*sample;
    else
        g = -label*sample*(t_exp/(1+t_exp));
    end
    x = InvFFT*(betaFT*(y+zeta) + eta_inv*x - g - gamma*sign(x));
    Fx = F*x;
    y  = wthresh(Fx - zeta,'s',mu/beta);
    zeta = zeta - Fx + y;
    xbar = (k*xbar + x)/(k+1);
    
    % Trace the log scaled results
    Num_i  = Num_i+1;
    if (Num_i >= checki)
        xs = [xs xbar];
        iters = [iters k];
        time_solving = cputime - t;
        times = [times time_solving];
        Num_i    = 0;
    end   
    
    % Stopping Criterion
    k = k + 1;
    if k>max_it && time_solving>time_min_run; done = true; end;
end

trace = []; 
trace.checki = checki; 
trace.xs     = xs;
trace.times  = times;
trace.iters  = iters;

outputs.x      = xbar;
outputs.iter   = k; 
outputs.trace  = trace;
end

