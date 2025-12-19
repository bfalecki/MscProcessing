function signalInfo = drcfg2signalInfo(cfg)
%DRCFG2SIGNALINFO this function converts demorad config structure to SignalInfo
%object
% input: cfg : structure  from readConfigDemorad function

if(cfg.Carrier < 100e9)
    device = "demorad24";
else
    device = "demorad122";
end

signalInfo = SignalInfo( ...
    "bandWidth",cfg.Bandwidth, ...
    "carrierFrequency",cfg.Carrier, ...
    "device",device, ...
    "PRF",cfg.PRF, ...
    "samplingFrequency",cfg.SamplingFreq, ...
    "timeStart",cfg.StartedAt);
end

