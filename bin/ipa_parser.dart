import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

const String lineNumber = 'line-number';

void main(final List<String> arguments) {
  exitCode = 0; // Presume success
  final ArgParser parser = ArgParser()
    ..addFlag(lineNumber, negatable: false, abbr: 'n');

  final ArgResults argResults = parser.parse(arguments);
  final List<String> paths = argResults.rest;

  dcat(paths, showLineNumbers: argResults[lineNumber] as bool);
}

Future<void> dcat(
  final List<String> paths, {
  final bool showLineNumbers = false,
}) async {
  if (paths.isEmpty) {
    // No files provided as arguments. Read from stdin and print each line.
    await stdin.pipe(stdout);
  } else {
    for (final String path in paths) {
      int lineNumber = 1;
      final Stream<String> lines = utf8.decoder
          .bind(File(path).openRead())
          .transform(const LineSplitter());
      try {
        await for (final String line in lines) {
          if (showLineNumbers) {
            stdout.write('${lineNumber++} ');
          }
          stdout.writeln(line);
        }
        // ignore: avoid_catches_without_on_clauses, TODO(vanyasem): Handle exception
      } catch (_) {
        await _handleError(path);
      }
    }
  }
}

Future<void> _handleError(final String path) async {
  if (FileSystemEntity.isDirectorySync(path)) {
    stderr.writeln('error: $path is a directory');
  } else {
    exitCode = 2;
  }
}
