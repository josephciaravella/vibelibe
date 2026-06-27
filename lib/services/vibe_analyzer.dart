import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VibeAnalyzer {
  /// Analyzes a remote audio preview URL and returns a 4D vibe vector:
  /// `[valence, danceability, energy, bpm]`
  /// Returns null if analysis fails.
  static Future<List<double>?> analyzePreview(String previewUrl) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final inputFilename = 'preview_$timestamp.mp3';
    final outputFilename = 'decoded_$timestamp.raw';
    
    File? inputFile;
    File? outputFile;
    
    try {
      print('VibeAnalyzer: Downloading preview from $previewUrl...');
      inputFile = await _downloadFile(previewUrl, inputFilename);
      
      print('VibeAnalyzer: Decoding audio using FFmpeg...');
      outputFile = await _decodeToPcm(inputFile, outputFilename);
      
      print('VibeAnalyzer: Reading PCM samples...');
      final bytes = await outputFile.readAsBytes();
      final samples = bytes.buffer.asInt16List(0, bytes.length ~/ 2);
      
      print('VibeAnalyzer: Running DSP feature analysis on ${samples.length} samples...');
      final features = _calculateFeatures(samples, 22050);
      
      print('VibeAnalyzer: Analysis complete. Results: $features');
      return [
        features['valence']!,
        features['danceability']!,
        features['energy']!,
        features['bpm']!,
      ];
    } catch (e) {
      print('VibeAnalyzer error: $e');
      return null;
    } finally {
      // Clean up temporary files
      try {
        if (inputFile != null && await inputFile.exists()) {
          await inputFile.delete();
        }
        if (outputFile != null && await outputFile.exists()) {
          await outputFile.delete();
        }
      } catch (cleanupError) {
        print('VibeAnalyzer cleanup warning: $cleanupError');
      }
    }
  }

  /// Downloads a remote file to temporary directory
  static Future<File> _downloadFile(String url, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    
    final client = HttpClient();
    // Configure client to follow redirects
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    
    if (response.statusCode != 200) {
      throw Exception('Failed to download audio preview: ${response.statusCode}');
    }
    
    final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Decodes MP3 input file to raw mono 16-bit PCM at 22050Hz
  static Future<File> _decodeToPcm(File inputFile, String outputFilename) async {
    final tempDir = await getTemporaryDirectory();
    final outputFile = File('${tempDir.path}/$outputFilename');
    
    if (await outputFile.exists()) {
      await outputFile.delete();
    }
    
    // Command decodes to 16-bit signed little-endian PCM, 1 channel (mono), 22050 Hz
    final command = '-y -i "${inputFile.path}" -f s16le -ac 1 -ar 22050 "${outputFile.path}"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      final errorMsg = logs.map((l) => l.getMessage()).join('\n');
      throw Exception('FFmpeg execution failed: $errorMsg');
    }
    
    return outputFile;
  }

  /// Runs lightweight beat tracking and RMS calculations on the mono PCM samples
  static Map<String, double> _calculateFeatures(Int16List samples, int sampleRate) {
    if (samples.isEmpty) {
      return {'valence': 0.5, 'danceability': 0.5, 'energy': 0.5, 'bpm': 120.0};
    }

    final double N = samples.length.toDouble();
    double sumSquares = 0.0;
    int zeroCrossings = 0;
    
    // Calculate RMS and Zero Crossing Rate
    for (int i = 0; i < samples.length; i++) {
      final double sample = samples[i] / 32768.0;
      sumSquares += sample * sample;
      
      if (i > 0) {
        final bool sign1 = samples[i] >= 0;
        final bool sign2 = samples[i - 1] >= 0;
        if (sign1 != sign2) {
          zeroCrossings++;
        }
      }
    }
    
    final double rms = math.sqrt(sumSquares / N);
    final double zcr = zeroCrossings / (N - 1);
    
    // Scale energy: map RMS from [0.05, 0.35] to [0.0, 1.0]
    final double energy = ((rms - 0.05) / 0.30).clamp(0.0, 1.0);

    // Beat tracking using energy novelty curve & autocorrelation
    // Frame size: 512 samples (~23.2ms at 22050Hz)
    // Hop size: 256 samples (~11.6ms, 50% overlap)
    const int frameSize = 512;
    const int hopSize = 256;
    
    final int numFrames = (samples.length - frameSize) ~/ hopSize;
    if (numFrames < 10) {
      return {'valence': 0.5, 'danceability': 0.5, 'energy': energy, 'bpm': 120.0};
    }
    
    final List<double> frameEnergy = List.filled(numFrames, 0.0);
    for (int f = 0; f < numFrames; f++) {
      final int start = f * hopSize;
      double sumSquaresFrame = 0.0;
      for (int i = 0; i < frameSize; i++) {
        final double sample = samples[start + i] / 32768.0;
        sumSquaresFrame += sample * sample;
      }
      frameEnergy[f] = math.sqrt(sumSquaresFrame / frameSize);
    }
    
    // Novelty curve (positive energy differences)
    final List<double> novelty = List.filled(numFrames - 1, 0.0);
    for (int f = 1; f < numFrames; f++) {
      final double diff = frameEnergy[f] - frameEnergy[f - 1];
      novelty[f - 1] = diff > 0 ? diff : 0.0;
    }
    
    // Autocorrelation of novelty curve for lags in BPM range [60, 200]
    // Hop rate = 22050 / 256 = 86.13 Hz
    // BPM = 60 * HopRate / lag = 5167.8 / lag
    // Lag range corresponding to [60, 200] BPM: [26, 86]
    const int lagMin = 26;
    const int lagMax = 86;
    
    final List<double> r = List.filled(lagMax - lagMin + 1, 0.0);
    double maxR = -1.0;
    int bestLag = lagMin;
    double sumR = 0.0;
    
    for (int lag = lagMin; lag <= lagMax; lag++) {
      double sumProduct = 0.0;
      int count = 0;
      for (int t = 0; t < novelty.length - lag; t++) {
        sumProduct += novelty[t] * novelty[t + lag];
        count++;
      }
      final double val = count > 0 ? sumProduct / count : 0.0;
      final int rIndex = lag - lagMin;
      r[rIndex] = val;
      sumR += val;
      if (val > maxR) {
        maxR = val;
        bestLag = lag;
      }
    }
    
    final double bpm = 5167.8 / bestLag;
    
    // Calculate danceability based on the strength of the beat peak
    final double meanR = sumR / r.length;
    double varianceR = 0.0;
    for (final val in r) {
      varianceR += (val - meanR) * (val - meanR);
    }
    final double stdR = math.sqrt(varianceR / r.length);
    final double peakRatio = stdR > 0 ? (maxR - meanR) / stdR : 0.0;
    final double danceability = ((peakRatio - 1.0) / 2.0).clamp(0.0, 1.0);
    
    // Calculate Valence (emotional positivity)
    // Valence is estimated using brightness (ZCR), energy, and tempo.
    final double zcrNormalized = (zcr / 0.15).clamp(0.0, 1.0);
    final double tempoNormalized = ((bpm - 60) / 140).clamp(0.0, 1.0);
    final double valence = (0.35 * zcrNormalized + 0.35 * energy + 0.30 * tempoNormalized).clamp(0.0, 1.0);
    
    return {
      'valence': valence,
      'danceability': danceability,
      'energy': energy,
      'bpm': bpm,
    };
  }
}
