# Audio

## Contents

- [Order of work](#order-of-work)
- [Narration](#narration)
- [Music](#music)
- [Sound effects](#sound-effects)
- [Sources](#sources)
- [Loudness targets](#loudness-targets)
- [Measure and set loudness](#measure-and-set-loudness)
- [Captions](#captions)
- [What the agent cannot judge](#what-the-agent-cannot-judge)

## Order of work

1. Pick the clock: narration or music. It sets shot lengths.
2. Voice first, then music under it, then sound effects, then captions.
3. Measure the final mix. Never trust the level of one stem.

A film with narration takes its timing from the voice file. A film without narration takes it from the music's beats or from the spec. Never write shot lengths from a word count and hope the voice fits: generate the voice, measure each line's duration, and set the shot lengths from those numbers.

## Narration

- Write the script in short spoken sentences, one idea per line, and match each line to a beat.
- Generate or record each line as its own file. Per-line files let you fix one line without redoing the others.
- Measure each file's duration with `ffprobe -v error -show_entries format=duration -of csv=p=0 line.wav`, then put the numbers into the spec's shot table, plus a short hold after each line.
- Check pronunciation of product names, acronyms and numbers by transcribing the generated audio with a speech-to-text capability and diffing it against the script.
- Voice rights: a cloned or licensed voice needs the speaker's consent and a licence that covers the use. Record both in the delivery note.

## Music

- Music is a bed. It stays under the voice and never competes with it. Lower it under speech with a fixed gain offset written in the spec, and raise it only in beats with no voice.
- Cut music to the film, not the film to the music, unless music is the clock. End on a musical resolution, or fade out over the last beat.
- Check the licence for the use (internal, public, paid ads). A track with no stated licence is not usable.
- Generated music is also a licence question: read the provider's current terms and record them.

## Sound effects

A sound effect needs a visible cause: something on screen lands, moves or changes at that frame. Put a cue in the spec for each one: frame, cause, file. Remove an effect with no cause, and remove ambient layers under voice unless the beat needs them. Effects belong to impacts, not to routine motion. If every element has a whoosh, none of them mean anything.

Place each effect so its first transient lands on the frame of the visible event, not on the frame where the animation starts.

## Sources

Name the capability you need, then check what is installed.

| Need | Capability | Notes |
|---|---|---|
| Voice | Text to speech, or a recorded voice | Ask before paid generation. Keep each line as a file |
| Music | Music generation, or licensed library tracks | Record licence and source |
| Effects | Sound effect generation, or a licensed library | Short files, trimmed at the start |
| Caption timing, script check | Speech to text with timestamps | Run on the final voice track |

The ElevenLabs skills cover all four (text-to-speech, music, sound-effects and speech-to-text) and install with `npx skills add elevenlabs/skills` (https://github.com/elevenlabs/skills). They need an API key and spend money, so ask first. Other providers work the same way: the playbook needs the files, not the vendor.

## Loudness targets

Loudness is measured as integrated programme loudness in LUFS, with true peak in dBTP. Use the platform's published number when it has one.

| Context | Target | True peak | Source |
|---|---|---|---|
| Broadcast programme (EBU R 128) | -23.0 LUFS integrated | Not above -1 dBTP | https://tech.ebu.ch/docs/r/r128.pdf (version 5) |
| Short-form content such as adverts and promos (EBU R 128 s1) | -23.0 LUFS integrated, and short-term loudness not above 5 LU over the target. No loudness range limit | Not above -1 dBTP | https://tech.ebu.ch/docs/r/r128s1.pdf |
| Streaming (EBU R 128 s2) | EBU recommends streaming programmes unchanged from the broadcast target, and notes that streaming services typically use a higher target | Per R 128 | https://tech.ebu.ch/docs/r/r128s2.pdf |
| Spotify (audio) | -14 LUFS integrated | Below -1 dBTP, and below -2 dBTP for masters louder than -14 LUFS | https://support.spotify.com/us/artists/article/loudness-normalization/ |
| Other online video platforms | Read the platform's current help page | Same | No official number confirmed in this research |

When the platform publishes no number and the user gives none, state the assumption in the brief. A common creator convention is -14 LUFS integrated with -1 dBTP peak for online-only delivery. It is a convention, not a confirmed platform rule, so mark it unverified in the spec and the delivery note.

Short films under about a minute: EBU notes that loudness range is not meaningful for very short programmes, so do not target it.

## Measure and set loudness

Measure the mix with ffmpeg's `ebur128` filter. The summary prints integrated loudness `I`, loudness range `LRA` and true peak `Peak`:

```bash
ffmpeg -hide_banner -nostats -i film.mp4 -vn -af ebur128=peak=true -f null - 2>&1 | sed -n '/Summary/,$p'
```

Fix level problems in the mix first: stem gains, music ducking, a limiter on the master. Use `loudnorm` for the final trim. It is a two-pass filter: pass one measures, pass two applies the measured values in linear mode, so dynamics are kept.

Pass one:

```bash
ffmpeg -hide_banner -nostats -i film.mp4 -vn -af loudnorm=I=-14:TP=-1:LRA=11:print_format=json -f null -
```

It prints JSON with `input_i`, `input_tp`, `input_lra`, `input_thresh` and `target_offset`. Pass two feeds them back and copies the picture untouched:

```bash
ffmpeg -i film.mp4 -c:v copy \
  -af "loudnorm=I=-14:TP=-1:LRA=11:measured_I=<input_i>:measured_TP=<input_tp>:measured_LRA=<input_lra>:measured_thresh=<input_thresh>:offset=<target_offset>:linear=true" \
  -ar 48000 -c:a aac -b:a 192k film_loud.mp4
```

Rules for these commands, from the filter documentation (https://ffmpeg.org/ffmpeg-filters.html#loudnorm):

- Defaults are `I=-24`, `LRA=7`, `TP=-2`. Always pass the targets you mean.
- `linear=true` needs all four `measured_*` values. If the target loudness range is below the source's, or the gain would push the true peak over the target, the filter falls back to dynamic mode.
- Dynamic mode upsamples to 192 kHz, so set the output rate explicitly with `-ar 48000`.
- `dual_mono=true` is for mono sources that will play on stereo speakers. Leave it off otherwise.

Lossy encoding moves the numbers slightly. Measure again on the delivered file and compare it with the target. If the true peak is over the limit after encoding, lower `TP` by a dB and repeat.

## Captions

| Question | Rule |
|---|---|
| Are captions needed? | WCAG 2.2 success criterion 1.2.2 (Level A) requires captions for prerecorded audio in synchronised media, except where the media is a clearly labelled alternative for text. Success criterion 1.2.5 (Level AA) adds audio description for prerecorded video. https://www.w3.org/TR/WCAG22/ |
| Sidecar or burned in? | Prefer a sidecar file (SRT or WebVTT) where the platform accepts one, since viewers can turn it off and platforms can translate it. Burn in only for platforms that need it, and keep the sidecar too |
| Where do timings come from? | Transcribe the final voice track with a speech-to-text capability that returns timestamps. Correct the text by hand against the script, then check the first and last cue against the audio |
| What layout? | Line length, lines per caption and reading speed come from `motion-design`. One published reference for subtitles: Netflix's English style guide sets 42 characters per line, 2 lines at most, up to 20 characters per second for adult programmes, a minimum of 5/6 second and a maximum of 7 seconds per event (https://partnerhelp.netflixstudios.com/hc/en-us/articles/217350977 and https://partnerhelp.netflixstudios.com/hc/en-us/articles/215758617) |

A minimal SRT cue:

```
1
00:00:00,500 --> 00:00:02,000
Text of the first caption
```

Add a sidecar to an MP4 as a soft subtitle track with `ffmpeg -i film.mp4 -i captions.srt -map 0 -map 1 -c copy -c:s mov_text -metadata:s:s:0 language=eng film_cc.mp4`. Not every player or platform reads that track, so also deliver the `.srt`.

Burning captions with ffmpeg uses the `subtitles` filter, which needs a build with libass. Check with `ffmpeg -filters | grep subtitles`. Some builds lack it, and then the captions must be drawn inside the engine instead.

## What the agent cannot judge

An agent cannot hear the film. It can measure loudness and peak, check durations, confirm that cues land on the right frames and that the transcript matches the script. It cannot judge tone, mix balance, a bad edit in a voice take, or whether music suits the mood. Say so in the delivery note and ask the user for one listen before publishing.
