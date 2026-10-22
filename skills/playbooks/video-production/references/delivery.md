# Render and delivery

## Contents

- [Render once](#render-once)
- [Encoding defaults](#encoding-defaults)
- [Verify the file](#verify-the-file)
- [Deliverables](#deliverables)
- [Delivery note](#delivery-note)

## Render once

Render only after the review loop is clean (no open P0 or P1) and the audio is measured. Each full render costs minutes, so a render to "see how it looks" is the review loop's job, not this step's.

Render at the spec's canvas and fps. Do not change fps at the encode step: a change retimes every cut and moves every audio cue.

Name the output after the content and version, not "final": `product-teaser-16x9-v1.mp4`. Keep earlier versions until the user accepts one.

## Encoding defaults

For web and social upload, the YouTube upload help page lists these as recommended: MP4 container, H.264 video, AAC-LC audio, 4:2:0 chroma subsampling, a 48 kHz audio sample rate, the moov atom at the front of the file (fast start), the frame rate the video was made at, and 16:9 as the standard ratio on computers, with vertical and square uploads accepted (https://support.google.com/youtube/answer/1722171). Other platforms publish their own pages: read the page for each target.

When the engine renders straight to a file, use its output settings for the same values. When ffmpeg encodes the final file from a high-quality render or an image sequence:

```bash
ffmpeg -i master.mp4 -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
  -c:a aac -b:a 192k -ar 48000 film.mp4
```

| Flag | Why |
|---|---|
| `-pix_fmt yuv420p` | The 4:2:0 format the platform page lists. It is also the most widely playable |
| `-movflags +faststart` | Moves the index to the start of the file so playback can begin before the download ends. The ffmpeg formats documentation describes it (https://ffmpeg.org/ffmpeg-formats.html) |
| `-c:a aac -ar 48000` | AAC-LC at 48 kHz, as listed above. `aac` is ffmpeg's built-in encoder |

The encoder uses its own default quality. Add `-crf <n>` only when a platform states a quality or bitrate, and read the encoder help (`ffmpeg -h encoder=libx264`) before choosing. For an image sequence from an engine, add `-framerate <fps> -i frame_%04d.png` ahead of the codec flags, and mux the audio file as a second input.

Encoder choice is a licence question: libx264 is a GPL library, and a build that includes it is GPL (see [engine-choice](engine-choice.md)). Check `ffmpeg -version` for `--enable-gpl` before shipping ffmpeg inside a product.

Keep a master: render a high-quality file once, and make platform versions from it, instead of re-rendering the engine for every ratio or encode.

## Verify the file

A render log that ends without errors proves the process finished. It does not prove the film is right. Check the file.

1. Probe the streams and compare them with the spec:

   ```bash
   ffprobe -v error -show_entries stream=index,codec_type,codec_name,width,height,pix_fmt,r_frame_rate,nb_frames,duration,sample_rate,channels -show_entries format=duration,size -of default=nw=1 film.mp4
   ```

   Expected: one video stream with the spec's width, height, fps and `yuv420p`, one audio stream at 48000 Hz, and `nb_frames` equal to the spec's total frames. Video and audio durations should match within a frame.
2. Capture five frames from the file (first, last, and three with the most text) and check them as in the [review loop](review-loop.md).
3. Measure loudness and true peak on the delivered file ([audio](audio.md)) and compare with the target.
4. Check the captions file against the audio: first and last cue, and one in the middle.
5. Compare the file size with the platform's upload limit, which its help page states.

Anything that cannot be checked by an agent goes in the delivery note: how it sounds, how it plays on a real phone, and how it looks on the target platform's player.

## Deliverables

| Item | Why |
|---|---|
| The film (`.mp4`) | The thing asked for |
| Captions sidecar (`.srt` or `.vtt`) | Accessibility and platform translation |
| Poster frame (`.png`) | Thumbnails, review, and a record of the opening |
| Source project and the render command | A later edit or a re-render in another ratio |
| Spec, review notes and approved stills | The record of what was agreed and checked |
| Asset credits | Fonts, music, voices, footage, generated media, each with licence |

Ask where to put them. If the user has no preference, use one folder per video, named after the content.

## Delivery note

Write a short note with the film. State measured facts as facts and unchecked items as unchecked.

```markdown
# Delivery: <title> v<n>

Files: <paths>
Format: <width x height>, <fps> fps, <duration> s, <codec>, <audio codec and rate>
Measured loudness: <integrated LUFS>, true peak <dBTP>, tool and command used
Target and source: <platform target and the page it came from, or the assumption and its label>

Engine and licence: <engine, version, licence file link, any condition the user must meet>
Assets: <each font, music, voice, footage, generated item with source and licence>
Generated media: <provider, model name as shown, prompt, terms link>, or "none"

Verified: <probe result, frames checked from the file, loudness, captions timing>
Not verified: <listening, real-device playback, platform player, anything unmeasured>
Open P2 findings: <list from the review notes>
Re-render: <exact command and where the source lives>
```

Keep the note to one screen. If something in "Not verified" matters to the use (for example public paid ads), say what the user should do before publishing.
