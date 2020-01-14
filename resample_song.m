function f = resample_song(f, Fs, new_Fs)

[Numer, Denom] = rat(new_Fs/Fs);
f = resample(f, Numer, Denom);

end

