import 'entities/payment.dart';

/// Resultado de validar un comprobante antes de subirlo.
sealed class ProofCheck {
  const ProofCheck();
}

final class ProofAccepted extends ProofCheck {
  const ProofAccepted(this.format);
  final ProofImageFormat format;
}

final class ProofRejected extends ProofCheck {
  const ProofRejected(this.code);

  /// `proof_empty`, `proof_too_large` o `proof_format_invalid`.
  final String code;
}

/// Valida tamaño y formato por la firma del archivo (no por la extensión).
ProofCheck checkProofBytes(List<int> bytes, {required int maxBytes}) {
  if (bytes.isEmpty) return const ProofRejected('proof_empty');
  if (bytes.length > maxBytes) return const ProofRejected('proof_too_large');
  final format = detectProofFormat(bytes);
  return format == null
      ? const ProofRejected('proof_format_invalid')
      : ProofAccepted(format);
}

ProofImageFormat? detectProofFormat(List<int> bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return ProofImageFormat.jpeg;
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return ProofImageFormat.png;
  }
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
      startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return ProofImageFormat.webp;
  }
  return null;
}

String proofFilename(ProofImageFormat format) => switch (format) {
      ProofImageFormat.jpeg => 'comprobante.jpg',
      ProofImageFormat.png => 'comprobante.png',
      ProofImageFormat.webp => 'comprobante.webp',
    };
