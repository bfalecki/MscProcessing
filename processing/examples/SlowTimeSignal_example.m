
slowTimeSignal = SlowTimeSignal();
% slowTimeSignal.initialize("signal",[1 0 1 0], ...
%     "signalInfo",...
%     SignalInfo("device","demorad24","PRF",1000,"carrierFrequency",24e9));

si = SignalInfo("carrierFrequency",24e9,"device","demorad","PRF",1000);
slowTimeSignal.initialize("signalInfo",si);
slowTimeSignal.setSignal([1 0 0 0 0 1  1 1 1])

stsph = SlowTimeSignalPhaser();
stsph.initialize("signalInfo",SignalInfo("carrierFrequency",10e9,"PRF",133));
stsph.setSignal([2 13 1 14 4 1 4 4 1])

stp = SlowTimePhase();
stp.initialize("signalInfo",si)
stp.setPhase([pi 2*pi 3*pi])

stsp = SlowTimeSignalPhaser();
stsp.initialize("signalInfo",si);
stsp.initializePhaserRelated("segmentEndIndices",1, "segmentStartIndices", 2)
stsp.setSignal([1 2 3 4 5] )

stpp = SlowTimePhasePhaser();
stpp.initialize("signalInfo",si)
stpp.setPhase([0 1 1 02 ])
stpp.initializePhaserRelated("segmentEndIndices",1, "segmentStartIndices", 2)
