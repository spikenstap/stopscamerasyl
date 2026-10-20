enum AnalysisType { text, url, phone, qr, incomingCall }

class AnalysisInput {
  const AnalysisInput(this.type, this.content, {this.context = ''});
  final AnalysisType type;
  final String content;
  final String context;
}
