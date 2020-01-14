function database = hash(song_spectrum, song_index, database)
num_win = length(song_spectrum);
linear_song = [];
for i=1:num_win
    row = song_spectrum{i};
    for subi=1:length(song_spectrum{i})
        entry = [row(subi), i];
        linear_song = [linear_song; entry];
    end
end

target_size = 5;
anchor_distance = 3;
for anchor_index=1:length(linear_song)-target_size-anchor_distance
    target_start = anchor_index + anchor_distance;
    target_end = target_start + target_size;
    anchor_frequency = linear_song(anchor_index, 1);
    anchor_time = linear_song(anchor_index, 2);
    for target_index = target_start:target_end
        database{anchor_frequency, linear_song(target_index, 1), linear_song(target_index, 2)-anchor_time+1, song_index} = anchor_time;
    end
end

end

