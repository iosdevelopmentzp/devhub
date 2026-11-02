import Foundation

enum FFmpegFixture {
    static let screenRecordingProbe = """
    {
        "streams": [
            {
                "index": 0,
                "codec_name": "h264",
                "profile": "Main",
                "codec_type": "video",
                "width": 3456,
                "height": 2234,
                "pix_fmt": "yuv420p",
                "r_frame_rate": "120/1",
                "avg_frame_rate": "10920/607",
                "time_base": "1/600",
                "duration": "5.020000",
                "nb_frames": "91",
                "tags": {
                    "handler_name": "Core Media Video",
                    "encoder": "H.264"
                }
            }
        ],
        "format": {
            "filename": "Screen Recording.mov",
            "nb_streams": 1,
            "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
            "start_time": "0.000000",
            "duration": "5.020000",
            "size": "2067145",
            "bit_rate": "3294254",
            "probe_score": 100
        }
    }
    """

    static let turnedProbeWithSound = """
    {
      "streams": [
        {
          "index": 0,
          "codec_name": "h264",
          "codec_type": "video",
          "width": 3456,
          "height": 2234,
          "r_frame_rate": "120/1",
          "avg_frame_rate": "200/11",
          "duration": "4.950000",
          "side_data_list": [
            {
              "side_data_type": "Display Matrix",
              "rotation": 90
            }
          ]
        },
        {
          "index": 1,
          "codec_name": "aac",
          "codec_type": "audio",
          "sample_rate": "44100",
          "channels": 1,
          "r_frame_rate": "0/0",
          "avg_frame_rate": "0/0",
          "duration": "5.000000"
        }
      ],
      "format": {
        "filename": "clip.mov",
        "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
        "duration": "5.000000",
        "size": "2083424",
        "bit_rate": "3333478"
      }
    }
    """

    static let audioOnlyProbe = """
    {"streams": [{"index": 0, "codec_name": "aac", "codec_type": "audio"}], "format": {"duration": "3.0", "size": "48000"}}
    """

    static let progressBlock = """
    frame=152
    fps=0.00
    stream_0_0_q=-1.0
    bitrate= 153.8kbits/s
    total_size=96096
    out_time_us=5000000
    out_time_ms=5000000
    out_time=00:00:05.000000
    dup_frames=83
    drop_frames=22
    speed=  21x
    progress=end
    """

    static let startBlock = """
    frame=0
    out_time_us=N/A
    out_time=N/A
    speed=N/A
    progress=continue
    """

    static let missingInput = """
    [in#0 @ 0x786c3c140] Error opening input: No such file or directory
    Error opening input file nothere.mov.
    Error opening input files: No such file or directory
    """

    static let version = """
    ffmpeg version 9.0.2 Copyright (c) 2000-2026 the FFmpeg developers
    built with Apple clang version 21.0.0 (clang-2100.3.34.2)
    """

    static let encoders = """
    Encoders:
     V..... = Video
     ------
     V....D libx264              libx264 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 (codec h264)
     V....D libx264rgb           libx264 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 RGB (codec h264)
     V....D h264_videotoolbox    VideoToolbox H.264 Encoder (codec h264)
     V....D hevc_videotoolbox    VideoToolbox H.265 Encoder (codec hevc)
    """

    static let encodersWithoutX264 = """
    Encoders:
     V....D h264_videotoolbox    VideoToolbox H.264 Encoder (codec h264)
     V....D libx264rgb           libx264 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 RGB (codec h264)
    """

    static let homebrewInstall = """
    ==> Downloading Homebrew API data
    ==> Fetching downloads for: ffmpeg
    ✔︎ Bottle x264 (r3222)
    ✔︎ Bottle ffmpeg (9.0.2_1)
    ==> Installing ffmpeg dependency: dav1d (1.5.4)
    ==> Pouring dav1d--1.5.4.arm64_tahoe.bottle.tar.gz
    🍺  /opt/homebrew/Cellar/dav1d/1.5.4: 16 files, 959.6KB
    ==> Pouring ffmpeg--9.0.2_1.arm64_tahoe.bottle.tar.gz
    """

    static let homebrewFailure = """
    ==> Fetching downloads for: ffmpeg
    Error: Cannot write to /opt/homebrew/Cellar
    Please check the folder permissions.
    """
}
