
# # ffmpeg -ss 00:06 -i raw.mp4  -c copy -copyts stripped.mp4
cp raw.mp4 stripped.mp4

ffmpeg -y -ss 00:06 -i stripped.mp4 -ss 00:06 -to 00:51 -copyts c1.1-spup.mp4
ffmpeg -y -ss 00:51 -i stripped.mp4 -ss 00:51 -to 01:30 -copyts c1.2.mp4
ffmpeg -y -ss 01:30 -i stripped.mp4 -ss 01:30 -to 23:20 -c copy -copyts c2-spup.mp4
ffmpeg -y -ss 24:46 -i stripped.mp4 -ss 24:46 -to 25:26 -copyts c3-spup.mp4
ffmpeg -y -ss 25:26 -i stripped.mp4 -ss 25:26 -to 26:50 -copyts c4.mp4

# ffmpeg -y -i c2-spup.mp4 -filter_complex "[0:v]setpts=0.01*PTS[v];[0:a]atempo=100[a]" -map "[v]" -map "[a]" c2.mp4
ffmpeg -y -i c1.1-spup.mp4 -filter:v "setpts=PTS/10" c1.1.mp4
ffmpeg -y -i c2-spup.mp4 -filter:v "setpts=PTS/120" c2.mp4
ffmpeg -y -i c3-spup.mp4 -filter:v "setpts=PTS/120" c3.mp4

# # ffmpeg -i c1.mp4 -i c2.mp4 -i c3.mp4 -i c4.mp4 -filter_complex "[0:v] [0:a] [1:v] [1:a] [2:v] [2:a] [3:v] [3:a] concat=n=4:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" output.mkv
ffmpeg -y -i c1.1.mp4 -i c1.2.mp4 -i c2.mp4 -i c3.mp4 -i c4.mp4 -filter_complex "[0:v] [1:v] [2:v] [3:v] [4:v] concat=n=5:v=1 [v]" -map "[v]" output.mp4


