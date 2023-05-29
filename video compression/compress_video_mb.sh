#!/bin/bash
mb_goal="$1"
file_path="$2"
if [ "$file_path" = "" ]
then
    printf "no file selected"
    read -t 5; exit 1
fi

if [ "$mb_goal" = "" ]
then
    printf "no size goal selected"
    read -t 5; exit 1
fi

file_cleanup() {
    rm "ffmpeg2pass-0.log"
    rm "ffmpeg2pass-0.log.mbtree"
}

trap file_cleanup EXIT

duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file_path")
duration=$(printf "%.0f\n" "$duration") # round to 0dp
bitrate=$(( (mb_goal * 8000) / $duration ))

# first part returns filename without extension
output_filename="$(echo $file_path | rev | cut -f 2- -d '.' | rev)_${mb_goal}MB.mp4"
echo "$output_filename"

printf "File is $duration seconds long.
Bitrate needs to be ${bitrate}kbps for video to be ${mb_goal}MB \n"

printf "first pass\n"
ffmpeg -v quiet -stats -y -i "$file_path" -c:v libx264 -b:v "$bitrate"k -pass 1 -vsync cfr -f null /dev/null
printf "second pass\n"
ffmpeg -v quiet -stats -y -i "$file_path" -c:v libx264 -b:v "$bitrate"k -pass 2 -c:a aac -b:a 128k "$output_filename"

printf "done!\n"
read -t 3
