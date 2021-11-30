function speed = spe(daq,x)

diameter=12;
rotarysignals = zeros(1,length(daq.timev));
rotarycounter = 0;
for j=2:length(rotarysignals)
    if daq.ai(3,j)>1 && daq.ai(4,j-1)<1 && daq.ai(4,j)>1
        rotarycounter=rotarycounter+1;
        rotarysignals(j)=rotarycounter;
    else
        rotarysignals(j)=rotarycounter;
    end
end

rotarysignals = rotarysignals(:,1:x:length(rotarysignals));
distance = rotarysignals * diameter * pi / 360;
timsec = daq.timev(:,1:x:length(daq.timev));
dD = diff(distance);
dT = diff(timsec);
speed = dD./dT;
speed = [speed zeros(1,1)];