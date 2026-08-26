<start>
1. clone repo
  git clone --depth 1 --single-branch https://github.com/FoggyCaligo/playlist.git
2. install downloader & tools 
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  .\setup-tools.ps1

tmux


<update>
yt-dlp --update-to master
<update-simple>
yt-dlp --update
winget upgrade yt-dlp

<use>
yt-dlp --no-abort-on-error --no-write-thumbnail -P "./playlist" --audio-quality 0 -t sleep "url"

<download - single song>
yt-dlp --no-abort-on-error --no-write-thumbnail  -P "./playlist" --audio-quality 0 --extract-audio -t sleep 

<download - playlist>
yt-dlp.exe --js-runtimes deno --remote-components ejs:github --cookies-from-browser firefox --no-abort-on-error --no-write-thumbnail --yes-playlist -P "./tmp" --audio-quality 0 --extract-audio --audio-format opus -t sleep "https://www.youtube.com/watch?v=e830egNulP8&list=PLLfWxWCqoR1s"


  

<download - video>
yt-dlp --keep-video --no-abort-on-error --no-write-thumbnail --paths [TYPES:]./tmp --audio-format mp4 --audio-quality 0 [URL]
yt-dlp -t mp4 [URL]

<help>
yt-dlp -h
