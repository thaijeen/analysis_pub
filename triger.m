function onset_index = triger(daq,timsec)


binarytriger = daq.ai(5,:) > 2;
onset = binarytriger - circshift(binarytriger, 1);
triger_index = find(onset==true);
onset_index = [];
for j = 1:length(triger_index)
    [~, miss_index] = min(abs(timsec - daq.timev(triger_index(j))));
    onset_index = [onset_index miss_index];
end