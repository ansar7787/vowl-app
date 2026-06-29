void main() { var map = <String, Map<String, int>>{}; var inner = map['test'] ?? {}; map['test'] = inner; print('success'); }
