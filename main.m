%% Shazam paper algorithm implementation by Matteo Meneghetti UNIVR
% Reset
clc;
close all;
clear;
clear sound;
workspace;
% Modify this to your own directory containing mp3/audio files
songs_dir = "/home/mat/Documents/MATLAB/shazam/songs";
%% Load already existing database (VERY VERY SLOW)
files = dir(songs_dir);
songnames = cell(length(files)-2, 2);
for index = 3:length(files)
    filename = files(index).name;
    songnames{index-2} = filename;
end
load(fullfile("/home/mat/Documents/MATLAB/shazam", "database.mat"));

%% Create new database from songs directory (FASTER?)
files = dir(songs_dir);
number_of_songs = length(files)-2;
database = cell(512, 512, 64, number_of_songs); %Huge 4D matrix: f1, f2, delta_window, song_index
files = dir(songs_dir);
songnames = cell(length(files)-2, 2);
for index = 3:length(files)
    filename = files(index).name;
    path = fullfile(songs_dir, filename);
    [sample, Fs] = audioread(path);
    % Passaggio da stereo a mono (2->1 canali) facendo la media tra i due
    % canali
    sample = 0.5*(sample(:, 1) + sample(:, 2));
    % Filtro passo basso per filtrare le frequenze maggiori di 5000Hz
    % Useless: the resample function apparently prevents aliasing by implementing a filter on his own
    maxFreq = 5000;
    [b, a] = butter(6, maxFreq/(Fs/2), 'low');
    sample = filter(b, a, sample);
    % Sottocampiono la canzone da 44100Hz a 11025Hz
    sample = resample_song(sample, Fs, 11025);
    fprintf("Generating fingerprint of %s: ", filename);
    song_spectrum = fingerprint(sample, 11025); % Extract peaks
    database = hash(song_spectrum, index-2, database);  % Update database
    songnames{index-2} = filename;
end
% As the database is a 4D matrix it weighs over 2GB, the flag -v7.3 is
% needed to save to file. For 20 songs it's faster to just create the
% database from scratch every time

% Uncomment these lines to save database to file (VERY SLOW)
% file_to_save = fullfile("/home/mat/Documents/MATLAB/shazam", "database.mat");
% save(file_to_save, "database", "-v7.3");

fprintf("Database generated successfully!\n\n");
%% Main
sampsec = 10;   % Sample duration (seconds)
snr_db = 15;    % Sample snr with added gaussian white noise (dB)

right = 0;  % Counter for successfull recognitions
wrong = 0;  % Counter for unsuccessfull recognitions

for contatore=1:10
fprintf("Counter: %i\n", contatore);
% Clear the results from the previous iteration
for song_index=1:length(songnames(:, 1))
    songnames{song_index, 2} = [];
end

% Choose the song randomly
selected_song = ceil(rand*number_of_songs);
filename = fullfile(songs_dir,songnames{selected_song, 1});
[song_signal, Fs] = audioread(filename);
mono_signal = 0.5*(song_signal(:, 1) + song_signal(:, 2));
signal_length = length(mono_signal);
sample_length = sampsec*Fs;

% Chosse sample start
sample_start = floor(rand*(signal_length-sample_length-1)+1);
% Extract sample
sample = mono_signal(sample_start:sample_start+sample_length-1);
% Add gaussian white noise
sample = awgn(sample, snr_db);

% Filtro passo basso di Butter di sesto ordine (!) per filtrare le frequenze maggiori di 5000Hz
maxFreq = 5000;
[b, a] = butter(6, maxFreq/(Fs/2));
sample = filter(b, a, sample);
% Sottocampiono la canzone da 44100Hz a 11025Hz
sample = resample_song(sample, Fs, 11025);
fprintf("Generating sample fingerprint: ");
song_spectrum = fingerprint(sample, 11025);

linear_song = [];
for i=1:length(song_spectrum)
    row = song_spectrum{i};
    for subi=1:length(song_spectrum{i})
        entry = [row(subi), i];
        linear_song = [linear_song; entry];
    end
end

target_size = 5;
anchor_distance = 3;

% Match with the whole database
current_winner = [1 -1];
for anchor_index=1:length(linear_song)-target_size-anchor_distance
    target_start = anchor_index + anchor_distance;
    target_end = target_start + target_size;
    anchor_frequency = linear_song(anchor_index, 1);
    anchor_time = linear_song(anchor_index, 2);
    for target_index = target_start:target_end
        for song_index=1:length(songnames(:, 1))
            absolute_time = database{anchor_frequency, linear_song(target_index, 1), linear_song(target_index, 2)-anchor_time+1, song_index};
            songnames{song_index, 2} = [songnames{song_index, 2} abs(absolute_time - anchor_time)];
        end
    end
end

for song_index=1:length(songnames(:, 1))
    if ~isempty(songnames{song_index, 2})
        [current_mode, freq_mode] = mode(songnames{song_index, 2});
        fprintf("%s: %i\n", songnames{song_index, 1}, freq_mode);
        if current_winner(2) <= freq_mode
            current_winner = [song_index, freq_mode];
        end
    end
end
fprintf("\nSelected song: %s\n", songnames{selected_song});
fprintf("My prediction is: %s\n\n", songnames{current_winner(1)});

if selected_song == current_winner(1)
    right = right + 1;
else
    wrong = wrong + 1;
end
end
fprintf("RIGHT: %i WRONG: %i\n\n", right, wrong);