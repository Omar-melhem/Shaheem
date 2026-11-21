// SHAHM DEMO (Task 37) — removes the debug demonstration mode using
// tool/demo/install_manifest.json. Run through `bash tool/demo/remove_demo.sh`.
//
//   --dry-run  checks everything and prints the plan; changes nothing.
//   --apply    the same checks, then removes the demo, regenerates the
//              localizations and verifies with `flutter analyze` and
//              `flutter test`; on a failed verification it puts every file
//              back as it was before the removal.
//   --skip-tests  (with --apply) skips `flutter test` (not recommended).
//
// Safety: only manifest-owned files and marked regions are touched; a region
// or exact edit that no longer matches its recorded hash/text stops the run
// before any change (owner edits inside demo regions are never overwritten).
// No git command is ever run. This file and remove_demo.sh are kept after a
// removal as a harmless entry point that then reports "demo absent".

import 'dart:convert';
import 'dart:io';

const _manifestPath = 'tool/demo/install_manifest.json';

/// References that must not survive a removal (outside tool/demo and the
/// regenerated localization output).
final _leftoverPatterns = [
  RegExp('SHAHM_DEMO'),
  RegExp(r'package:mobile_frontend/demo/'),
  RegExp(r'assets/demo/'),
  RegExp(r'\bDemoApp\b'),
  RegExp(r'demoAppOverlay|demoShellBuilder|demoHomeBuilder|DemoHomeWallet'),
  RegExp(r'"@?demo[A-Z]\w*"\s*:'),
];

/// Where leftovers are searched.
const _scanRoots = ['lib', 'test', 'tool', 'docs', 'assets'];
const _scanFiles = ['pubspec.yaml', 'CLAUDE.md', 'l10n.yaml'];
const _scanSkip = ['tool/demo/', 'lib/helper/translation/generated/'];
const _textExtensions = ['.dart', '.arb', '.yaml', '.md', '.json', '.sh'];

/// Paths a manifest-owned file may have.
const _ownedPrefixes = [
  'lib/demo/',
  'test/demo_mode_test.dart',
  'tool/demo/',
  'assets/demo/',
];

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run');
  final skipTests = args.contains('--skip-tests');
  if (apply == dryRun) {
    stderr.writeln('Usage: remove_demo.sh --dry-run | --apply [--skip-tests]');
    exit(64);
  }
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() ||
      !pubspec.readAsStringSync().contains('name: mobile_frontend')) {
    stderr.writeln('Run from mobile_frontend/ (pubspec.yaml not found).');
    exit(64);
  }

  final manifestFile = File(_manifestPath);
  if (!manifestFile.existsSync()) {
    final leftovers = _scanLeftovers(const {});
    if (leftovers.isEmpty) {
      stdout.writeln('SHAHM demo absent: nothing to remove.');
      exit(0);
    }
    stderr.writeln('No manifest, but demo references remain:');
    leftovers.forEach(stderr.writeln);
    stderr.writeln('Manual review needed; nothing was changed.');
    exit(2);
  }

  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final problems = <String>[];
  final notes = <String>[];

  // ---- Files to delete.
  final deletions = <String>[];
  final archiveOnly = <String>[];
  for (final group in ['created_files', 'owner_supplied_files']) {
    for (final entry
        in (manifest[group] as List).cast<Map<String, dynamic>>()) {
      final path = entry['path'] as String;
      if (!_isOwnedPath(path)) {
        problems.add('Refusing a path outside the demo areas: $path');
        continue;
      }
      if (entry['retain'] == true) continue;
      final file = File(path);
      if (!file.existsSync()) {
        notes.add('already absent: $path');
        continue;
      }
      final expected = entry['sha256'] as String?;
      if (expected != null && _sha256(file.readAsBytesSync()) != expected) {
        notes.add('changed since install (archived before deletion): $path');
        archiveOnly.add(path);
      }
      deletions.add(path);
    }
  }

  // ---- Edits to pre-existing files.
  final newContents = <String, String>{};
  for (final edit in (manifest['edits'] as List).cast<Map<String, dynamic>>()) {
    final path = edit['file'] as String;
    final file = File(path);
    if (!file.existsSync()) {
      problems.add('$path is missing (edit ${edit['id']}).');
      continue;
    }
    final text = newContents[path] ?? file.readAsStringSync();
    final original = edit['original'] as String;
    if (edit['kind'] == 'exact') {
      final installed = edit['installed'] as String;
      final count = installed.allMatches(text).length;
      if (count != 1) {
        problems.add(
          '$path: the installed text of "${edit['id']}" was found $count '
          'times (expected 1); it was edited after install.',
        );
        continue;
      }
      newContents[path] = text.replaceFirst(installed, original);
      continue;
    }
    final id = edit['id'] as String;
    final range = _region(text, id);
    if (range == null) {
      problems.add('$path: markers for "$id" are missing or not unique.');
      continue;
    }
    final regionText = text.substring(range.$1, range.$2);
    if (_sha256(utf8.encode(regionText)) != edit['region_sha256']) {
      problems.add(
        '$path: the demo region "$id" was edited after install; '
        'resolve it by hand (nothing was changed).',
      );
      continue;
    }
    newContents[path] = text.replaceRange(range.$1, range.$2, original);
  }

  // ---- Leftover references after the planned removal.
  final leftovers = _scanLeftovers(newContents, deleted: deletions.toSet());
  if (leftovers.isNotEmpty) {
    problems.add(
      'Demo references would remain outside the manifest:\n  '
      '${leftovers.join('\n  ')}',
    );
  }

  // ---- Restoration report against the pre-install hashes.
  final baseline = (manifest['baseline_sha256'] as Map).cast<String, String>();
  for (final MapEntry(key: path, value: content) in newContents.entries) {
    final same = _sha256(utf8.encode(content)) == baseline[path];
    notes.add(
      same
          ? 'restores exactly the pre-install bytes: $path'
          : 'restored demo parts; other (owner) edits kept: $path',
    );
  }

  stdout.writeln('SHAHM demo removal plan (${apply ? 'apply' : 'dry run'}):');
  for (final path in newContents.keys) {
    stdout.writeln('  edit    $path');
  }
  for (final path in deletions) {
    stdout.writeln('  delete  $path');
  }
  for (final retained
      in (manifest['created_files'] as List).cast<Map<String, dynamic>>().where(
        (e) => e['retain'] == true,
      )) {
    stdout.writeln('  keep    ${retained['path']} (maintenance entry point)');
  }
  stdout.writeln('  then    flutter gen-l10n');
  for (final n in notes) {
    stdout.writeln('  note    $n');
  }

  if (problems.isNotEmpty) {
    stderr.writeln('\nSTOPPED — nothing was changed:');
    for (final p in problems) {
      stderr.writeln('  - $p');
    }
    exit(1);
  }
  if (dryRun) {
    stdout.writeln('\nDry run OK: no file was changed.');
    exit(0);
  }

  // ---- Apply, with a backup outside the repository.
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backup = Directory(
    '${Directory.systemTemp.path}/shahm_demo_removal_$stamp',
  )..createSync(recursive: true);
  final touched = {
    ...newContents.keys,
    ...deletions,
    ...(manifest['regenerated'] as List).cast<String>(),
  };
  for (final path in touched) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final copy = File('${backup.path}/$path')..createSync(recursive: true);
    copy.writeAsBytesSync(file.readAsBytesSync());
  }
  stdout.writeln('\nBackup of every touched file: ${backup.path}');

  void restore() {
    for (final path in touched) {
      final copy = File('${backup.path}/$path');
      if (copy.existsSync()) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(copy.readAsBytesSync());
      }
    }
  }

  for (final MapEntry(key: path, value: content) in newContents.entries) {
    File(path).writeAsStringSync(content);
  }
  for (final path in deletions) {
    File(path).deleteSync();
  }
  for (final dir in ['lib/demo', 'assets/demo']) {
    _deleteEmptyDirs(Directory(dir));
  }

  final steps = [
    ['flutter', 'gen-l10n'],
    ['flutter', 'analyze', '--no-fatal-infos', '--no-fatal-warnings'],
    if (!skipTests) ['flutter', 'test'],
  ];
  for (final step in steps) {
    stdout.writeln('\n\$ ${step.join(' ')}');
    final result = await Process.start(
      step.first,
      step.sublist(1),
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    if (await result.exitCode != 0) {
      stderr.writeln('\n"${step.join(' ')}" failed: restoring the demo.');
      restore();
      await Process.run('flutter', ['gen-l10n'], runInShell: true);
      stderr.writeln('Restored from ${backup.path}. Nothing is lost.');
      exit(1);
    }
  }

  final remaining = _scanLeftovers(const {});
  if (remaining.isNotEmpty) {
    stderr.writeln('Unexpected demo references remain:');
    remaining.forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln(
    '\nSHAHM demo removed. Verified: gen-l10n, analyze'
    '${skipTests ? '' : ', tests'}, no demo references left.\n'
    'Kept: tool/demo/remove_demo.sh and remove_demo.dart (they now report '
    '"demo absent"; delete them whenever you like).',
  );
}

bool _isOwnedPath(String path) =>
    !path.startsWith('/') &&
    !path.split('/').contains('..') &&
    _ownedPrefixes.any(path.startsWith);

/// [start, end) of the marked region [id]: from the start of the line with
/// `SHAHM_DEMO_START id` to the end of the line with `SHAHM_DEMO_END id`.
(int, int)? _region(String text, String id) {
  final start = RegExp('^.*SHAHM_DEMO_START $id( |\$).*\n', multiLine: true);
  final end = RegExp('^.*SHAHM_DEMO_END $id( |\$).*\n', multiLine: true);
  final starts = start.allMatches(text).toList();
  final ends = end.allMatches(text).toList();
  if (starts.length != 1 || ends.length != 1) return null;
  if (ends.single.start < starts.single.start) return null;
  return (starts.single.start, ends.single.end);
}

List<String> _scanLeftovers(
  Map<String, String> overrides, {
  Set<String> deleted = const {},
}) {
  final hits = <String>[];
  final files = <String>{
    for (final root in _scanRoots)
      if (Directory(root).existsSync())
        for (final f in Directory(root).listSync(recursive: true))
          if (f is File) f.path,
    for (final f in _scanFiles)
      if (File(f).existsSync()) f,
  };
  for (final path in files) {
    if (deleted.contains(path) || _scanSkip.any(path.startsWith)) continue;
    if (!_textExtensions.any(path.endsWith)) continue;
    final text = overrides[path] ?? File(path).readAsStringSync();
    for (final pattern in _leftoverPatterns) {
      if (pattern.hasMatch(text)) {
        hits.add('$path (${pattern.pattern})');
        break;
      }
    }
  }
  return hits;
}

void _deleteEmptyDirs(Directory dir) {
  if (!dir.existsSync()) return;
  for (final child in dir.listSync()) {
    if (child is Directory) _deleteEmptyDirs(child);
  }
  if (dir.listSync().isEmpty) dir.deleteSync();
}

// ---- SHA-256 (FIPS 180-4), so no package is needed.

const _k = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

String _sha256(List<int> data) {
  const mask = 0xffffffff;
  int rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & mask;
  final bitLength = data.length * 8;
  final bytes = [...data, 0x80];
  while (bytes.length % 64 != 56) {
    bytes.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    bytes.add((bitLength >> (i * 8)) & 0xff);
  }
  final h = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final w = List<int>.filled(64, 0);
  for (var chunk = 0; chunk < bytes.length; chunk += 64) {
    for (var i = 0; i < 16; i++) {
      final j = chunk + i * 4;
      w[i] =
          (bytes[j] << 24) |
          (bytes[j + 1] << 16) |
          (bytes[j + 2] << 8) |
          bytes[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & mask;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      final ch = (e & f) ^ ((~e & mask) & g);
      final t1 = (hh + s1 + ch + _k[i] + w[i]) & mask;
      final s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & mask;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & mask;
    }
    h[0] = (h[0] + a) & mask;
    h[1] = (h[1] + b) & mask;
    h[2] = (h[2] + c) & mask;
    h[3] = (h[3] + d) & mask;
    h[4] = (h[4] + e) & mask;
    h[5] = (h[5] + f) & mask;
    h[6] = (h[6] + g) & mask;
    h[7] = (h[7] + hh) & mask;
  }
  return h.map((x) => x.toRadixString(16).padLeft(8, '0')).join();
}
