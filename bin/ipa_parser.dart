import 'dart:io';

import 'package:archive/archive_io.dart' as archive_io;
import 'package:args/args.dart';
import 'package:propertylistserialization/propertylistserialization.dart';

const String lineNumber = 'line-number';

void main(final List<String> arguments) {
  exitCode = 0; // Presume success

  final ArgParser parser = ArgParser();
  final ArgResults argResults = parser.parse(arguments);
  final List<String> paths = argResults.rest;

  extractIpaMetadata(paths);
}

Future<void> extractIpaMetadata(final List<String> argsPaths) async {
  if (argsPaths.isEmpty) {
    // No files provided as arguments
    stderr.writeln('error: no files provided as arguments');
  } else {
    for (final String argsPath in argsPaths) {
      final bool isIpa = argsPath.toLowerCase().endsWith('ipa');
      if (!isIpa && !argsPath.toLowerCase().endsWith('zip')) {
        stderr.writeln('error: unsupported file type $argsPath');
        continue;
      }

      final String archivePath;
      if (isIpa) {
        archivePath = '$argsPath.zip';
      } else {
        archivePath = argsPath;
      }

      const String extractionPath = 'out';
      try {
        final File binary = File(argsPath);
        if (binary.existsSync()) {
          // Append .zip to ipa file
          if (isIpa) {
            binary.copySync(archivePath);
          }

          await archive_io.extractFileToDisk(archivePath, extractionPath);

          final File itunesMetadata = File(
            '$extractionPath/iTunesMetadata.plist',
          );
          if (itunesMetadata.existsSync()) {
            final String metadata = itunesMetadata.readAsStringSync();
            final Map<String, Object> plist =
                PropertyListSerialization.propertyListWithString(metadata)
                    as Map<String, Object>;
            stdout
              ..write('iconUrl: ')
              ..writeln("'${plist['softwareIcon57x57URL']}',")
              ..write('name: ')
              ..writeln("'${plist['bundleDisplayName']}',")
              ..write('version: ')
              ..writeln("'${plist['bundleShortVersionString']}',")
              ..write('bundleId: ')
              ..writeln("'${plist['softwareVersionBundleId']}',");
          } else {
            stderr.writeln('error: $argsPath is not a valid IPA');
            continue;
          }
        } else {
          stderr.writeln('error: file $argsPath does not exist');
          continue;
        }
        // ignore: avoid_catches_without_on_clauses, TODO(vanyasem): Handle exception
      } catch (e) {
        print(e);
        await _handleError(argsPath);
      } finally {
        // Delete temporary ipa.zip file
        if (isIpa) {
          final File archive = File(archivePath);
          if (archive.existsSync()) {
            archive.deleteSync();
          }
        }

        // Cleanup extraction artifacts
        final Directory extractedArchive = Directory(extractionPath);
        if (extractedArchive.existsSync()) {
          extractedArchive.deleteSync(recursive: true);
        }
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
