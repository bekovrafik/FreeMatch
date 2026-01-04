import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/free.png');
  if (!file.existsSync()) {
    stdout.writeln('Error: free.png not found');
    exit(1);
  }

  final logo = img.decodeImage(file.readAsBytesSync());
  if (logo == null) {
    stdout.writeln('Error: Could not decode image');
    exit(1);
  }

  // Dimensions
  // Flutter code:
  // Logo Container: 160x160 (assuming logo itself fits inside padded)
  // Our logo_v3.png might be any size. let's assume we want substantial padding.

  // Canvas Size: let's make it 2.5x the logo width to allow for big soft shadows
  // If logo is 500px, canvas is 1250px.
  final size = (logo.width * 2.5).toInt();
  final center = size ~/ 2;

  // Create blank canvas
  var canvas = img.Image(width: size, height: size); // Transparent

  // Colors
  // Amber: 0xFFFBBF24 (R=251, G=191, B=36)
  // Opacity 0.1 ~= 25.
  final amberAlpha = img.ColorRgba8(251, 191, 36, 25);

  // --- 1. SHADOW LAYER ---
  // Flutter: spreadRadius: 10. Relative to a 160px box, that's ~6%.
  // Logo is inside the box. Let's say box radius is logo.width * 0.7
  final boxRadius = (logo.width * 0.7).toInt();
  final spreadRadius = (logo.width * 0.1).toInt(); // approx 15% of radius

  // Draw shadow circle (box + spread)
  // We'll draw it on the main canvas then blur the whole thing (since it's empty so far)
  img.fillCircle(
    canvas,
    x: center,
    y: center,
    radius: boxRadius + spreadRadius,
    color: amberAlpha,
  );

  // Apply Blur (blurRadius: 40 in flutter is quite large. ~25% of box size)
  final blurAmount = (boxRadius * 0.25).toInt();
  canvas = img.gaussianBlur(canvas, radius: blurAmount);

  // --- 2. CONTAINER LAYER (Background) ---
  // Flutter: color: Colors.amber.withValues(alpha: 0.1)
  // We draw this *over* the shadow.
  img.fillCircle(
    canvas,
    x: center,
    y: center,
    radius: boxRadius,
    color: amberAlpha,
  );

  // --- 3. LOGO ---
  // Composite logo centered
  final logoX = (size - logo.width) ~/ 2;
  final logoY = (size - logo.height) ~/ 2;
  img.compositeImage(canvas, logo, dstX: logoX, dstY: logoY);

  // Save
  final outFile = File('assets/images/free.png');
  outFile.writeAsBytesSync(img.encodePng(canvas));

  stdout.writeln('Success: Created assets/images/free.png ($size x $size)');
}
