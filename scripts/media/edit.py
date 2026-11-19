#!/usr/bin/env python3
"""Edits the screen recording made by ProductCaptureTests.testRecordTour into the website's videos.

Only iSensa's own windows are kept: every scene is cropped to the window (or popover) frame the test
logged, so nothing else on the screen reaches the output. No frame is generated or retouched; the
edit is crop, scale, cross-fade and an occasional static close-up of a real frame region.

    edit.py <recording.mp4> <timeline.json> <recording-start-epoch> <output-folder>

Outputs: hero.mp4 / hero.webm (short muted loop), tour.mp4 (complete tour), hero.jpg and tour.jpg posters (website/scripts/posters.mjs turns them into WebP).
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

INK = "0x0A0F1A"  # The app icon's ink, also the website's dark background.
FPS = 30
FADE = 0.5


def run(*args):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


def rounded_mask(path, width, height, radius):
    # Anti-aliased rounded rectangle; d is the distance outside the inner rectangle.
    r = radius
    d = f"hypot(max(max({r}-X,X-({width}-1-{r})),0),max(max({r}-Y,Y-({height}-1-{r})),0))"
    run("-f", "lavfi", "-i", f"color=black:s={width}x{height}", "-vf",
        f"format=gray,geq=lum='255*clip({r}+0.5-{d},0,1)'", "-frames:v", "1", str(path))


def shadow(path, mask, width, height):
    run("-i", str(mask), "-f", "lavfi", "-i", "color=black:s=1920x1080", "-filter_complex",
        f"[0]pad=1920:1080:(ow-{width})/2:(oh-{height})/2+26:black,boxblur=36:2,format=gray[a];"
        "[1]format=rgba[k];[k][a]alphamerge,colorchannelmixer=aa=0.55", "-frames:v", "1", str(path))


class Editor:
    def __init__(self, video, timeline, start, work):
        self.video = video
        self.work = Path(work)
        info = json.loads(Path(timeline).read_text())
        self.scale = info["scale"]
        self.events = info["events"]
        self.offset = self.events[0]["wall"] - start - self.events[0]["t"]
        self.masks = {}
        self.count = 0

    def scene(self, name):
        names = [e["scene"] for e in self.events]
        index = names.index(name)
        event, following = self.events[index], self.events[index + 1]
        return event["t"] + self.offset, following["t"] + self.offset, event["frame"]

    def pixels(self, frame, inset_top=0):
        x, y, w, h = frame
        s = self.scale
        return int(w * s), int((h - inset_top) * s), int(x * s), int((y + inset_top) * s)

    def decoration(self, width, height, radius):
        key = (width, height, radius)
        if key not in self.masks:
            mask = self.work / f"mask-{width}x{height}.png"
            shade = self.work / f"shadow-{width}x{height}.png"
            rounded_mask(mask, width, height, radius)
            shadow(shade, mask, width, height)
            self.masks[key] = (mask, shade)
        return self.masks[key]

    def framed(self, name, lead, length, height=940, radius=18, inset_top=0):
        """The window (or popover) on the ink background, with its own corners and a soft shadow."""
        start, end, frame = self.scene(name)
        cw, ch, cx, cy = self.pixels(frame, inset_top)
        width = int(round(cw * height / ch / 2) * 2)
        mask, shade = self.decoration(width, height, radius)
        out = self.work / f"clip{self.count:02}.mp4"
        self.count += 1
        span = f"{min(length, end - start - lead - 0.2):.3f}"
        run("-ss", f"{start + lead:.3f}", "-t", span, "-i", self.video,
            "-loop", "1", "-t", span, "-i", str(mask), "-loop", "1", "-t", span, "-i", str(shade),
            "-f", "lavfi", "-t", span, "-i", f"color={INK}:s=1920x1080:r={FPS}", "-filter_complex",
            f"[0]crop={cw}:{ch}:{cx}:{cy},scale={width}:{height}:flags=lanczos,fps={FPS},format=rgba[w];"
            "[1]format=gray[m];[w][m]alphamerge[wa];"
            "[3][2]overlay=0:0:shortest=1[b];[b][wa]overlay=(W-w)/2:(H-h)/2:shortest=1,format=yuv420p",
            *self.encoding(), str(out))
        return out

    def closeup(self, name, lead, length, region):
        """A still-camera close-up on part of the window: a crop of the real recording, scaled up."""
        start, end, frame = self.scene(name)
        x, y, w, h = region
        s = self.scale
        fx, fy = frame[0], frame[1]
        out = self.work / f"clip{self.count:02}.mp4"
        self.count += 1
        run("-ss", f"{start + lead:.3f}", "-t", f"{min(length, end - start - lead - 0.2):.3f}", "-i", self.video,
            "-vf", f"crop={int(w * s)}:{int(h * s)}:{int((fx + x) * s)}:{int((fy + y) * s)},"
                   f"scale=1920:1080:flags=lanczos,fps={FPS},format=yuv420p",
            *self.encoding(), str(out))
        return out

    def bare(self, name, lead, length, width=1600):
        """The window alone, for the hero, where the page draws the frame and corners."""
        start, end, frame = self.scene(name)
        cw, ch, cx, cy = self.pixels(frame)
        height = int(round(ch * width / cw / 2) * 2)
        out = self.work / f"clip{self.count:02}.mp4"
        self.count += 1
        run("-ss", f"{start + lead:.3f}", "-t", f"{min(length, end - start - lead - 0.2):.3f}", "-i", self.video,
            "-vf", f"crop={cw}:{ch}:{cx}:{cy},scale={width}:{height}:flags=lanczos,fps={FPS},format=yuv420p",
            *self.encoding(), str(out))
        return out

    @staticmethod
    def encoding():
        return ["-an", "-c:v", "libx264", "-preset", "medium", "-crf", "14", "-pix_fmt", "yuv420p"]


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True).stdout
    return float(out)


def join(clips, output, fade=FADE, extra=()):
    """Cross-fades the clips in order."""
    inputs = []
    for clip in clips:
        inputs += ["-i", str(clip)]
    graph, label, elapsed = [], "[0]", duration(clips[0])
    for index, clip in enumerate(clips[1:], start=1):
        offset = elapsed - fade
        graph.append(f"{label}[{index}]xfade=transition=fade:duration={fade}:offset={offset:.3f}[v{index}]")
        label = f"[v{index}]"
        elapsed = offset + duration(clip)
    run(*inputs, "-filter_complex", ";".join(graph), "-map", label, *extra, str(output))


def main():
    video, timeline, start, output = sys.argv[1], sys.argv[2], float(sys.argv[3]), Path(sys.argv[4])
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        edit = Editor(video, timeline, start, work)
        h264 = ["-an", "-c:v", "libx264", "-preset", "slow", "-profile:v", "high", "-pix_fmt", "yuv420p", "-movflags", "+faststart"]

        # Hero: a short, quiet loop of the live dashboard and three screens, ending where it began.
        hero = [edit.bare("overview", 1.2, 7), edit.bare("thermals", 1.0, 4), edit.bare("history", 1.0, 4),
                edit.bare("cpu", 1.0, 4), edit.bare("overview", 1.2, 1.2)]
        join(hero, output / "hero.mp4", fade=0.6, extra=[*h264, "-crf", "24", "-r", str(FPS)])
        run("-i", str(output / "hero.mp4"), "-an", "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "36", "-row-mt", "1",
            "-cpu-used", "3", "-pix_fmt", "yuv420p", str(output / "hero.webm"))
        run("-i", str(output / "hero.mp4"), "-frames:v", "1", "-q:v", "2", str(output / "hero.jpg"))

        # Tour: every module, with close-ups where the detail matters.
        tour = [
            edit.framed("overview", 1.2, 5.5),
            edit.closeup("overview", 6.8, 3, (250, 60, 1040, 585)),
            edit.framed("cpu", 1.0, 4.5),
            edit.framed("gpu", 1.0, 4),
            edit.framed("thermals", 1.0, 4),
            edit.closeup("thermals", 5.0, 2.6, (230, 40, 1060, 596)),
            edit.framed("battery", 1.0, 4.5),
            edit.framed("fans", 1.0, 4.5),
            edit.framed("memory", 1.0, 4),
            edit.framed("history", 1.0, 3.8),
            edit.closeup("history", 4.8, 2.8, (210, 250, 1080, 608)),
            edit.framed("settings-general", 0.8, 3.4, height=820, radius=16),
            edit.framed("settings-menuBar", 0.8, 3.4, height=820, radius=16),
            edit.framed("settings-notifications", 0.8, 3.6, height=820, radius=16),
            # The popover, below the menu bar (the bar itself shows other apps' icons).
            edit.framed("popover", 0.8, 5.5, height=936, radius=22, inset_top=30),
        ]
        join(tour, output / "tour.mp4", extra=[*h264, "-crf", "21", "-r", str(FPS)])
        run("-ss", "2", "-i", str(output / "tour.mp4"), "-frames:v", "1", "-q:v", "2", str(output / "tour.jpg"))


if __name__ == "__main__":
    main()
