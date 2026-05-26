import 'package:file_picker/file_picker.dart';

const int userSupportMaxAttachmentCount = 5;
const int userSupportMaxAttachmentBytes = 5 * 1024 * 1024;
const int userSupportMaxTitleLength = 120;
const int userSupportMaxMessageLength = 5000;

const Set<String> userSupportAllowedAttachmentExtensions = <String>{
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'gif',
  'doc',
  'docx',
  'txt',
  'zip',
};

const Set<String> userSupportBlockedAttachmentExtensions = <String>{
  'svg',
  'html',
  'htm',
  'js',
  'exe',
};

bool userSupportContainsLetterOrNumber(String value) {
  return RegExp(r'[A-Za-z0-9]').hasMatch(value);
}

String userSupportExtensionFromFileName(String fileName) {
  final normalized = fileName.trim().toLowerCase();
  final index = normalized.lastIndexOf('.');
  if (index < 0 || index == normalized.length - 1) {
    return '';
  }
  return normalized.substring(index + 1);
}

String userSupportAttachmentIdentity(PlatformFile file) {
  final path = file.path?.trim() ?? '';
  return '${file.name.trim().toLowerCase()}|${file.size}|$path';
}
