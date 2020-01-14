function song_spectrum = fingerprint(f, Fs)
sig_len = length(f);
window_len = 4096;
number_of_windows = floor(sig_len/window_len);
mean_coeff = 1.8;
song_spectrum = cell(number_of_windows, 1);

for window_index=1:number_of_windows
    if ~mod(window_index, floor(number_of_windows/10))
        fprintf("~");
    end
    window_start = (window_index-1)*(window_len)+1;
    window_end = window_start + window_len - 1;
    window = f(window_start:window_end).*hamming(window_len);
    Fwindow = abs(fft(window, window_len));
    
    % 0-10, 10-20, 20-40, 40-80, 80-160, 160-511
    group1 = Fwindow(1:10);
    group2 = Fwindow(11:20);
    group3 = Fwindow(21:40);
    group4 = Fwindow(41:80);
    group5 = Fwindow(81:160);
    group6 = Fwindow(161:512);
    
    [max1, max1_i] = max(group1);
    [max2, max2_i] = max(group2);
    max2_i = max2_i + 10;
    [max3, max3_i] = max(group3);
    max3_i = max3_i + 20;
    [max4, max4_i] = max(group4);
    max4_i = max4_i + 40;
    [max5, max5_i] = max(group5);
    max5_i = max5_i + 80;
    [max6, max6_i] = max(group6);
    max6_i = max6_i + 160;
    
    maxes = [[max1, max1_i];[max2, max2_i];[max3, max3_i];[max4, max4_i];[max5, max5_i];[max6, max6_i]];
    average_value = mean(maxes(:,1))*mean_coeff;
    result = maxes(maxes(:,1) >= average_value, 2);
    song_spectrum{window_index, 1} = result;
end
fprintf("\n");
end